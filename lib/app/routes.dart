class AppRoutes {
  static const splash = '/launch';
  static const jobs = '/';
  static const sales = '/plans';
  static const jobDetail = '/job-detail';
  static const materialForm = '/material-form';
  static const drafts = '/drafts';
  static const account = '/account';
  static const customization = '/customization';
  static const privacyPolicy = '/privacy-policy';
}

class JobDetailRouteArgs {
  const JobDetailRouteArgs({required this.jobId});

  final String jobId;
}

class MaterialFormRouteArgs {
  const MaterialFormRouteArgs({required this.jobId, required this.draftId});

  final String jobId;
  final String draftId;
}

class DraftsRouteArgs {
  const DraftsRouteArgs({this.jobId});

  final String? jobId;
}
