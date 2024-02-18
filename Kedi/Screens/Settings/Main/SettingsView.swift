//
//  SettingsView.swift
//  Kedi
//
//  Created by Saffet Emin Reisoğlu on 2/2/24.
//

import SwiftUI

struct SettingsView: View {
    
    @StateObject private var viewModel = SettingsViewModel()
    
    @ScaledMetric private var supporterImageWidth: CGFloat = 80
    
    @State private var showingSupporterView = false
    
    var body: some View {
        makeBody()
            .navigationTitle("Settings")
            .background(Color.systemGroupedBackground)
            .refreshable {
                await viewModel.refresh()
            }
    }
    
    @ViewBuilder
    private func makeBody() -> some View {
        switch viewModel.state {
        case .empty:
            ContentUnavailableView(
                "No Data",
                systemImage: "xmark.circle"
            )
            
        case .error(let error):
            ContentUnavailableView(
                "Error",
                systemImage: "exclamationmark.triangle",
                description: Text(error.localizedDescription)
            )
            
        case .loading,
                .data:
            List {
                Section {
                    Button {
                        showingSupporterView.toggle()
                    } label: {
                        HStack(spacing: 0) {
                            Text("🚀")
                                .fixedSize(horizontal: false, vertical: true)
                                .font(.system(size: supporterImageWidth - 2))
                                .frame(width: supporterImageWidth, height: 0)
                            
                            VStack(alignment: .center) {
                                Text("Become a Supporter")
                                
                                Text("Support indie development!")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            
                            HStack() {
                                Spacer()
                                
                                Image(systemName: "chevron.forward")
                                    .font(.footnote)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.trailing)
                            .frame(width: supporterImageWidth)
                        }
                        .padding(.vertical, 10)
                        .background {
                            RoundedRectangle(cornerRadius: 20, style: .continuous).fill(.accent)
                        }
                        .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                    .padding(.vertical)
                } footer: {
                    Text("Kedi is a free and [open-source \(Text(imageSystemName: "arrow.up.forward").foregroundStyle(.accent))](https://github.com/sereisoglu/Kedi) RevenueCat client. Kedi was build by a solo [developer \(Text(imageSystemName: "arrow.up.forward").foregroundStyle(.accent))](https://x.com/sereisoglu). If Kedi has made your life easier and you want to support development, you can become a supporter! If you become a supporter, you are eligible to use alternative app icons.")
                        .padding(.horizontal)
                }
                .listRowInsets(.zero)
                .listRowBackground(Color.clear)
                
                Section {
                    SettingsAccountItemView(
                        key: "Id",
                        value: viewModel.me?.distinctId ?? "n/a"
                    )
                    SettingsAccountItemView(
                        key: "Name",
                        value: viewModel.me?.name ?? "n/a"
                    )
                    SettingsAccountItemView(
                        key: "Email",
                        value: viewModel.me?.email ?? "n/a"
                    )
                    SettingsAccountItemView(
                        key: "Current Plan",
                        value: viewModel.me?.currentPlan?.capitalized ?? "n/a"
                    )
                    SettingsAccountItemView(
                        key: "Current MTR",
                        value: viewModel.me?.billingInfo?.currentMtr?.formatted(.currency(code: "USD").precision(.fractionLength(0))) ?? "n/a"
                    )
                    SettingsAccountItemView(
                        key: "Trailing 30-day MTR",
                        value: viewModel.me?.billingInfo?.trailing30dayMtr?.formatted(.currency(code: "USD").precision(.fractionLength(0))) ?? "n/a"
                    )
                    SettingsAccountItemView(
                        key: "First Transaction Date",
                        value: viewModel.me?.firstTransactionAt?.format(to: .iso8601WithoutMilliseconds)?.formatted(date: .abbreviated, time: .shortened) ?? "n/a"
                    )
                    SettingsAccountItemView(
                        key: "Token Expires",
                        value: viewModel.authTokenExpiresDate?.relativeFormat(to: .full).capitalized ?? "n/a"
                    )
                } header: {
                    Text("Account")
                }
                
                Section {
                    GeneralListView(
                        imageAsset: .systemImage("app"),
                        title: "App Icon"
                    )
                    .overlay {
                        NavigationLink(value: "appIcon") { EmptyView() }.opacity(0)
                    }
                } header: {
                    Text("Customization")
                }
                
                Section {
                    Button {
                        WidgetsManager.shared.reloadAll()
                    } label: {
                        Text("Force Update")
                            .foregroundStyle(.blue)
                    }
                } header: {
                    Text("Widgets")
                }
                
                Section {
                    Link(destination: URL(string: "mailto:sereisoglu@gmail.com")!) {
                        GeneralListView(
                            imageAsset: .systemImage("envelope"),
                            title: "Support",
                            subtitle: "sereisoglu@gmail.com",
                            accessoryImageSystemName: "arrow.up.right"
                        )
                    }
                    
                    Link(destination: URL(string: "https://github.com/sereisoglu/Kedi")!) {
                        GeneralListView(
                            imageAsset: .systemImage("star"),
                            title: "Rate Kedi",
                            subtitle: "Rate us on the App Store – it really helps!",
                            accessoryImageSystemName: "arrow.up.right"
                        )
                    }
                    
                    GeneralListView(
                        imageAsset: .systemImage("info.circle"),
                        title: "About"
                    )
                    .overlay {
                        NavigationLink(value: "about") { EmptyView() }.opacity(0)
                    }
                } header: {
                    Text("Kedi")
                }
                
                Section {
                    AsyncButton {
                        viewModel.handleSignOutButton()
                    } label: {
                        Text("Sign Out")
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity)
                            .multilineTextAlignment(.center)
                    }
                }
                
                Section {
                    Text("Version \(Bundle.main.versionNumber ?? "1.0") (\(Bundle.main.buildNumber ?? "1"))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                        .listRowBackground(Color.clear)
                }
                .listSectionSpacing(.compact)
            }
            .navigationDestination(for: String.self) { screen in
                switch screen {
                case "appIcon":
                    AppIconView()
                case "about":
                    AboutView()
                default:
                    Text("Unknown destination!")
                }
            }
            .sheet(isPresented: $showingSupporterView) {
                NavigationStack {
                    SupporterView()
                        .environmentObject(PurchaseManager.shared)
                }
            }
            .redacted(reason: viewModel.state == .loading ? .placeholder : [])
            .disabled(viewModel.state == .loading)
        }
    }
}

#Preview {
    SettingsView()
}
