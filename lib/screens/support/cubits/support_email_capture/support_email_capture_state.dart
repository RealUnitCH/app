part of 'support_email_capture_cubit.dart';

sealed class SupportEmailCaptureState extends Equatable {
  const SupportEmailCaptureState();

  @override
  List<Object?> get props => [];
}

final class SupportEmailCaptureInitial extends SupportEmailCaptureState {
  const SupportEmailCaptureInitial();
}

final class SupportEmailCaptureSubmitting extends SupportEmailCaptureState {
  const SupportEmailCaptureSubmitting();
}

final class SupportEmailCaptureSuccess extends SupportEmailCaptureState {
  const SupportEmailCaptureSuccess();
}

final class SupportEmailCaptureFailure extends SupportEmailCaptureState {
  final String message;

  const SupportEmailCaptureFailure({required this.message});

  @override
  List<Object?> get props => [message];
}
