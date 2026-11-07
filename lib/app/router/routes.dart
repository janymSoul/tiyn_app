abstract final class Routes {
  static const splash = '/splash';
  static const signIn = '/sign-in';

  static const teenJoin = '/teen/join';
  static const teenHome = '/teen/home';
  static String teenTask(String id) => '$teenHome/task/$id';
  static String teenMilestone(String id) => '$teenHome/milestone/$id';

  static const parentHome = '/parent/home';
  static String parentTeen(String id) => '$parentHome/teen/$id';
  static const parentTeenPattern = 'teen/:id';
  static const parentNew = '/parent/new';

  /// The create form for a task or a milestone (a milestone's step carries
  /// [milestoneId] and the milestone's [milestoneDeadline]).
  static String parentNewFor(
    String teenId, {
    bool milestone = false,
    String? milestoneId,
    DateTime? milestoneDeadline,
  }) => Uri(
    path: parentNew,
    queryParameters: {
      'teenId': teenId,
      if (milestone) 'kind': 'milestone',
      'milestoneId': ?milestoneId,
      if (milestoneDeadline != null)
        'milestoneDeadline': milestoneDeadline.toUtc().toIso8601String(),
    },
  ).toString();

  static const parentReview = '/parent/review';
  static String parentReviewTask(String id) => '$parentReview/$id';
  static const parentReviewTaskPattern = ':id';
}
