import Foundation
import Observation

@Observable
class ConstraintViewModel {
    var constraints = Constraints.default
    var isLoading = false
    var isSaving = false
    var errorMessage: String?
    var saveSuccess = false

    func load() async {
        isLoading = true
        errorMessage = nil
        do {
            constraints = try await APIClient.shared.getConstraints()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func save() async {
        isSaving = true
        errorMessage = nil
        do {
            try await APIClient.shared.updateConstraints(constraints)
            saveSuccess = true
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }
}
