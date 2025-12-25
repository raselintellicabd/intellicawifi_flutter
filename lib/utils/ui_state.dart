enum UiStatus { loading, success, error }

class UiState<T> {
  final UiStatus status;
  final T? data;
  final String? message;

  UiState._({required this.status, this.data, this.message});

  factory UiState.loading() => UiState._(status: UiStatus.loading);
  factory UiState.success(T data) => UiState._(status: UiStatus.success, data: data);
  factory UiState.error(String message) => UiState._(status: UiStatus.error, message: message);
}
