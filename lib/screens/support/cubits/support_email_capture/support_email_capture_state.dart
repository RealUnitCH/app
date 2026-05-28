part of 'support_email_capture_cubit.dart';

abstract class SupportEmailCaptureState extends Equatable {
  const SupportEmailCaptureState();

  @override
  List<Object?> get props => [];
}

class SupportEmailCaptureInitial extends SupportEmailCaptureState {
  const SupportEmailCaptureInitial();
}

class SupportEmailCaptureLoading extends SupportEmailCaptureState {
  const SupportEmailCaptureLoading();
}

class SupportEmailCaptureSuccess extends SupportEmailCaptureState {
  const SupportEmailCaptureSuccess();
}

enum SupportEmailCaptureError { mergeRequested, unknown }

class SupportEmailCaptureFailure extends SupportEmailCaptureState {
  final SupportEmailCaptureError error;
  final String message;

  const SupportEmailCaptureFailure({
    required this.error,
    required this.message,
  });

  @override
  List<Object?> get props => [error, message];
}
