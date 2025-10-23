class SiteConfig {
  final int siteNo;
  final bool showPhoneField;
  final bool enableQR;
  final String? name;

  SiteConfig({
    required this.siteNo,
    this.showPhoneField = false,
    this.enableQR = false,
    this.name,
  });

  // Simple static factory — tweak to load from backend if you add a config endpoint
  static SiteConfig forSite(int siteNo) {
    if (siteNo == 2) {
      return SiteConfig(siteNo: siteNo, showPhoneField: true, enableQR: true, name: 'Site 2');
    }
    // default
    return SiteConfig(siteNo: siteNo, showPhoneField: false, enableQR: false, name: 'Site $siteNo');
  }
}
