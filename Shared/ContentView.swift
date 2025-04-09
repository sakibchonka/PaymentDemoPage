// 1. Setup UI of the ContentView. Try to keep it as similar as possible.
// 2. Subscribe to the timer and count seconds down from 60 to 0 on the ContentView.
// 3. Present PaymentModalView as a sheet after tapping on the "Open payment" button.
// 4. Load payment types from repository in PaymentInfoView. Show loader when waiting for the response. No need to handle error.
// 5. List should be refreshable.
// 6. Show search bar for the list to filter payment types. You can filter items in any way.
// 7. User should select one of the types on the list. Show checkmark next to the name when item is selected.
// 8. Show "Done" button in navigation bar only if payment type is selected. Tapping this button should hide the modal.
// 9. Show "Finish" button on ContentScreen only when "payment type" was selected.
// 10. Replace main view with "FinishView" when user taps on the "Finish" button.

import SwiftUI
import Combine

class Model: ObservableObject {

    let processDurationInSeconds: Int = 60
    var repository: PaymentTypesRepository = PaymentTypesRepositoryImplementation()
	@Published var searchText: String = ""
	@Published var paymentTypes: [PaymentType] = []
	@Published var timeRemaining: Int
	@Published var isLoading: Bool = true
	@Published var isFinished: Bool = false
	@Published var selectedPaymentType: PaymentType?
	
	var filteredPaymentTypes: [PaymentType] {
		if searchText.isEmpty {
			return paymentTypes
		} else {
			return paymentTypes.filter {
				$0.name.localizedCaseInsensitiveContains(searchText)
			}
		}
	}
	
    var cancellables: [AnyCancellable] = []

    init() {
		self.timeRemaining = processDurationInSeconds
		startTimer()
		loadPaymentTypes()
    }
	
	private func loadPaymentTypes() {
		repository.getTypes { [weak self] result in
			DispatchQueue.main.async {
				switch result {
				case .success(let types):
					self?.paymentTypes = types
				case .failure(let error):
					print(error)
				}
				self?.isLoading = false
			}
		}
	}
	
	func refreshPaymentTypes() {
		isLoading = true
		loadPaymentTypes()
	}
	
	private func startTimer() {
		Timer
			.publish(every: 1, on: .main, in: .common)
			.autoconnect()
			.sink { [weak self] _ in
				guard let self = self else { return }
				
				if self.timeRemaining > 0 {
					self.timeRemaining -= 1
				}
			}
			.store(in: &cancellables)
	}
}

struct ContentView: View {
	@State private var showPaymentModal = false
	@StateObject private var model = Model()
	
	var body: some View {
		if model.isFinished {
			FinishView()
		} else {
			ZStack {
				Color(.blue)
					.ignoresSafeArea()
				VStack {
					Spacer()
					// Seconds should count down from 60 to 0
					Text("You have only \(model.timeRemaining) seconds left to get the discount")
						.font(.system(size: 25, weight: .heavy, design: .rounded))
						.foregroundStyle(.white)
						.multilineTextAlignment(.center)
					
					Spacer()
					
					Button(action: {
						// Action here
						showPaymentModal = true
					}) {
						Text("Open payment")
							.foregroundColor(.blue)
							.frame(maxWidth: .infinity)
							.padding()
							.background(Color.white)
							.cornerRadius(10)
					}
					.padding(.horizontal)
					
					// Visible only if payment type is selected
					if model.selectedPaymentType != nil {
						Button(action: {
							
						}){
							Text("Finish")
								.foregroundColor(.blue)
								.frame(maxWidth: .infinity)
								.padding()
								.background(Color.white)
								.cornerRadius(10)
						}
						.padding(.horizontal)
					}
					
				}
				.padding([.horizontal, .bottom])
				//			.fullScreenCover(isPresented: $showPaymentModal) {
				//				PaymentModalView()
				//			}
				.sheet(isPresented: $showPaymentModal) {
					PaymentModalView(model: model)
				}
			}
		}
	}
}

struct FinishView: View {
    var body: some View {
        Text("Congratulations")
    }
}

struct PaymentModalView : View {
	@ObservedObject var model: Model
    var body: some View {
        NavigationView {
			PaymentInfoView(model: model)
        }
    }
}

struct PaymentInfoView: View {
//	@StateObject var model = Model()
	@ObservedObject var model: Model
	@Environment(\.dismiss) var dismiss
	
    var body: some View {
        // Load payment types when presenting the view. Repository has 2 seconds delay.
        // User should select an item.
        // Show checkmark in a selected row.
        //
        // No need to handle error.
        // Use refreshing mechanism to reload the list items.
        // Show loader before response comes.
        // Show search bar to filter payment types
        //
        // Finish button should be only available if user selected payment type.
        // Tapping on Finish button should close the modal.

		NavigationStack {
			
			if model.isLoading {
				ProgressView("Loading payment types...")
			} else {
				
				List(model.filteredPaymentTypes, id:\.self) { item in
					HStack {
						Text(item.name)
						Spacer()
						
						if model.selectedPaymentType == item {
							Image(systemName: "checkmark")
						}
					}
					.contentShape(Rectangle())
					.onTapGesture {
						if model.selectedPaymentType == item {
							model.selectedPaymentType = nil
						} else {
							model.selectedPaymentType = item
						}
					}
					
				}
				.refreshable {
					model.refreshPaymentTypes()
				}
				.navigationTitle("Payment info")
				.navigationBarItems(trailing:
										Group {
					
					if model.selectedPaymentType != nil {
						Button("Finish", action: {
							model.isFinished = true
							dismiss()
						})
					}
				}
				)
				.searchable(text: $model.searchText, prompt: "Search")
				
			}
			
			
		}
    }
}

//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//		PaymentInfoView()
//    }
//}
