/// Dashboard state definitions for the AgriFlow mobile application.
library;

enum DashboardStatus {
  initial,
  loading,
  success,
  empty,
  error,
  refreshing,
}

class DashboardState<T> {
  final DashboardStatus status;
  final T? data;
  final String? errorMessage;
  final bool isNetworkError;

  const DashboardState({
    required this.status,
    this.data,
    this.errorMessage,
    this.isNetworkError = false,
  });

  factory DashboardState.initial() => const DashboardState(
        status: DashboardStatus.initial,
      );

  factory DashboardState.loading() => const DashboardState(
        status: DashboardStatus.loading,
      );

  factory DashboardState.refreshing(T currentData) => DashboardState(
        status: DashboardStatus.refreshing,
        data: currentData,
      );

  factory DashboardState.success(T data) => DashboardState(
        status: DashboardStatus.success,
        data: data,
      );

  factory DashboardState.empty() => const DashboardState(
        status: DashboardStatus.empty,
      );

  factory DashboardState.error(
    String message, {
    bool isNetworkError = false,
    T? previousData,
  }) =>
      DashboardState(
        status: DashboardStatus.error,
        data: previousData,
        errorMessage: message,
        isNetworkError: isNetworkError,
      );

  bool get isInitial => status == DashboardStatus.initial;
  bool get isLoading => status == DashboardStatus.loading;
  bool get isRefreshing => status == DashboardStatus.refreshing;
  bool get isSuccess => status == DashboardStatus.success;
  bool get isError => status == DashboardStatus.error;
  bool get isEmpty => status == DashboardStatus.empty;
}
