// Role selection is a navigation preference, not an authorization grant.
enum MarketplaceRole { artisan, buyer, courier, admin }

enum AuthEntry { signIn, signUp }

extension MarketplaceRoleLabels on MarketplaceRole {
  String get label => switch (this) {
    MarketplaceRole.artisan => 'Artisan / Studio Maker',
    MarketplaceRole.buyer => 'Buyer / Patron',
    MarketplaceRole.courier => 'Fragile Delivery Courier',
    MarketplaceRole.admin => 'Marketplace Curator & Admin',
  };

  String get signUpLabel => switch (this) {
    MarketplaceRole.artisan => 'Create Studio Account',
    MarketplaceRole.buyer => 'Create Collector Account',
    MarketplaceRole.courier => 'Create Courier Account',
    MarketplaceRole.admin => 'Create Curator Account',
  };

  String get signInLabel => switch (this) {
    MarketplaceRole.artisan => 'Sign In to Studio',
    MarketplaceRole.buyer => 'Sign In to Collection',
    MarketplaceRole.courier => 'Sign In to Delivery',
    MarketplaceRole.admin => 'Sign In to Administration',
  };
}
