abstract final class Routes {
  static const splash = '/splash';
  static const signIn = '/sign-in';

  static const teenJoin = '/teen/join';
  static const teenHome = '/teen/home';

  static const parentHome = '/parent/home';
  static String parentTeen(String id) => '$parentHome/teen/$id';
  static const parentTeenPattern = 'teen/:id';
  static const parentReview = '/parent/review';
}
