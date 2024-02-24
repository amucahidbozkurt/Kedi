//
//  OverviewViewModel.swift
//  Kedi
//
//  Created by Saffet Emin Reisoğlu on 2/2/24.
//

import Foundation

final class OverviewViewModel: ObservableObject {
    
    private let apiService = APIService.shared
    private let meManager = MeManager.shared
    private let widgetsManager = WidgetsManager.shared
    
    @Published private(set) var state: GeneralState = .data
    
    @Published private(set) var configs: [OverviewItemConfig] = OverviewItemConfig.get()
    @Published private(set) var items: [OverviewItemConfig: OverviewItem] = .placeholder(configs: OverviewItemConfig.get())
    
    init() {
        Task {
            await fetchAll()
        }
    }
    
    private func fetchAll() async {
        await withDiscardingTaskGroup { group in
            group.addTask { [weak self] in
                await self?.fetchOverview()
            }
            
            configs.forEach { config in
                group.addTask { [weak self] in
                    await self?.fetchChart(config: config)
                }
            }
        }
    }
    
    @MainActor
    private func fetchOverview() async {
        do {
            let data = try await apiService.request(
                type: RCOverviewResponse.self,
                endpoint: .overview
            )
            
            setItem(type: .mrr, value: .mrr(data?.mrr ?? 0))
            setItem(type: .subsciptions, value: .subsciptions(data?.activeSubscribersCount ?? 0))
            setItem(type: .trials, value: .trials(data?.activeTrialsCount ?? 0))
            setItem(config: .init(type: .revenue, timePeriod: .last28Days), value: .revenue(data?.revenue ?? 0))
            setItem(config: .init(type: .users, timePeriod: .last28Days), value: .users(data?.activeUsersCount ?? 0))
            setItem(config: .init(type: .installs, timePeriod: .last28Days), value: .installs(data?.installsCount ?? 0))
        } catch {
            state = .error(error)
        }
    }
    
    @MainActor
    private func fetchChart(config: OverviewItemConfig) async {
        let type = config.type
        
        guard let chartName = type.chartName,
              let chartIndex = type.chartIndex else {
            return
        }
        
        do {
            let data = try await apiService.request(
                type: RCChartResponse.self,
                endpoint: .charts(.init(
                    name: chartName,
                    resolution: config.timePeriod.resolution,
                    startDate: config.timePeriod.startDate,
                    endDate: config.timePeriod.endDate
                ))
            )
            
            let chartValues: [LineAndAreaMarkChartValue]? = data?.values?.map { .init(
                date: .init(timeIntervalSince1970: $0[safe: 0] ?? 0),
                value: $0[safe: chartIndex] ?? 0
            ) }
            
            switch type {
            case .mrr,
                    .subsciptions,
                    .trials,
                    .users,
                    .installs:
                items[config]?.set(chartValues: chartValues)
            case .revenue:
                if config.timePeriod == .last28Days {
                    items[config]?.set(chartValues: chartValues)
                } else {
                    items[config]?.set(value: .revenue(data?.summary?["total"]?["Total Revenue"] ?? 0), chartValues: chartValues)
                }
            case .arr:
                items[config]?.set(value: .arr(chartValues?.last?.value ?? 0), chartValues: chartValues)
            case .proceeds:
                items[config]?.set(value: .proceeds(data?.summary?["total"]?["Proceeds"] ?? 0), chartValues: chartValues)
            case .newUsers:
                items[config]?.set(value: .newUsers(Int(chartValues?.last?.value ?? 0)), chartValues: chartValues)
            case .churnRate:
                items[config]?.set(value: .churnRate(chartValues?.last?.value ?? 0), chartValues: chartValues)
            case .subsciptionsLost:
                items[config]?.set(value: .subsciptionsLost(Int(chartValues?.last?.value ?? 0)), chartValues: chartValues)
            }
        } catch {
            print(error)
        }
    }
    
    func refresh() async {
        widgetsManager.reloadAll()
        await fetchAll()
    }
    
    // MARK: - Items
    
    func getItems() -> [OverviewItem] {
        configs.compactMap { items[$0] }
    }
    
    private func setItem(
        type: OverviewItemType,
        value: OverviewItemValue
    ) {
        guard let config = configs.first(where: { $0.type == type }) else {
            return
        }
        items[config]?.set(value: value)
    }
    
    private func setItem(
        config: OverviewItemConfig,
        value: OverviewItemValue?,
        chartValues: [LineAndAreaMarkChartValue]? = nil
    ) {
        if let value {
            items[config]?.set(value: value, chartValues: chartValues)
        } else {
            items[config]?.set(chartValues: chartValues)
        }
    }
    
    func addItem() {
        let config = OverviewItemConfig(type: .revenue, timePeriod: .allTime)
        let item = OverviewItem(config: config)
        
        configs.insert(config, at: 0)
        items[config] = item
        
        OverviewItemConfig.set(to: configs)
        
        Task {
            await fetchChart(config: config)
        }
    }
    
    func removeItem() {
        OverviewItemConfig.set(to: nil)
    }
}
