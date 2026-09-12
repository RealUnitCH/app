abstract final class WalletConnectConfig {
  static const projectId = String.fromEnvironment(
    'WALLETCONNECT_PROJECT_ID',
    defaultValue: 'e1c63d938472e3e0d0ec1fd2669e7271',
  );

  static const metadataName = 'RealUnit Wallet';
  static const metadataUrl = 'https://realunit.app';
  static const redirectNative = 'realunit-wallet://wc';
  static const chainIds = [1, 10, 137];
  static const methods = <String>[
    'personal_sign',
    'eth_sign',
    'eth_signTypedData',
    'eth_signTypedData_v4',
    'wallet_switchEthereumChain',
    'eth_chainId',
    'eth_accounts',
    'eth_requestAccounts',
  ];
  static const events = <String>['chainChanged', 'accountsChanged'];
}
