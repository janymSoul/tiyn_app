/// A bank app the parent can open to send the money. One entry per bank;
/// adding one is a line here plus the package in the manifest's `<queries>`
/// (a test fails if it is missing). The backend never hears of banks.
class Bank {
  const Bank({
    required this.id,
    required this.displayName,
    required this.androidPackage,
  });

  final String id;
  final String displayName;
  final String androidPackage;
}

/// Only banks whose package id has been checked on a real phone belong here
/// (UC-09). Kaspi and Forte are added once theirs are verified.
const freedomBank = Bank(
  id: 'freedom',
  displayName: 'Freedom Bank',
  androidPackage: 'ffinbank.MyFreedom',
);

const supportedBanks = <Bank>[freedomBank];
