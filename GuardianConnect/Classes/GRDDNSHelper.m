//
//  GRDDNSHelper.m
//  GuardianConnect
//
//  Created by Constantin Jacob on 15.02.23.
//  Copyright © 2023 Sudo Security Group Inc. All rights reserved.
//

#import "GRDDNSHelper.h"

@interface GRDDNSHelper()

@property (readwrite, copy) NEDNSSettingsManager *dnsSettingManager;
@property (readwrite, copy) NSArray *defaultOnDemandRules;
@property (readwrite, copy) NSString *dnsfRoamingClientId;

@end

@implementation GRDDNSHelper

+ (instancetype)sharedInstance {
	static dispatch_once_t onceToken;
	static GRDDNSHelper *shared;
	dispatch_once(&onceToken, ^{
		shared = [GRDDNSHelper new];
		
		shared.dnsSettingManager = [NEDNSSettingsManager sharedManager];
		
		NEOnDemandRuleConnect *vpnServerConnectRule = [[NEOnDemandRuleConnect alloc] init];
		vpnServerConnectRule.interfaceTypeMatch = NEOnDemandRuleInterfaceTypeAny;
		shared.defaultOnDemandRules = @[vpnServerConnectRule];
		
		shared.dnsfRoamingClientId = [GRDKeychain getPasswordStringForAccount:kGRDKeychainStr_DNSFRoamingClientId];
	});
	
	return shared;
}


# pragma mark - NEDNSSettings Wrappers

+ (void)loadDNSSettingsConfigurationWithCompletion:(void (^)(NSString * _Nullable))completion {
	GRDDNSHelper *helper = [GRDDNSHelper sharedInstance];
	if (helper.dnsSettingManager == nil) {
		helper.dnsSettingManager = [NEDNSSettingsManager sharedManager];
	}
	
	[helper.dnsSettingManager loadFromPreferencesWithCompletionHandler:^(NSError * _Nullable error) {
		if (error != nil) {
			if (completion) completion([NSString stringWithFormat:@"Failed to load the DNS settings configuration: %@", [error localizedDescription]]);
			return;
		}
		
		if (completion) completion(nil);
		return;
	}];
}

- (void)setDNSSettingsConfigurationWithType:(GRDDNSSettingsType)dnsSettingsType roamingClientId:(NSString *)roamingClientId andCompletion:(void (^)(NSString * _Nullable))completion {
	if (dnsSettingsType != DNSSettingsTypeDOH) {
		if (completion) completion([NSString stringWithFormat:@"Unsupported DNS settings type passed. Please provide a DNS settings configuration of type DNSSettingsTypeDOH"]);
		return;
	}
	
	if (self.localizedDNSConfigurationDescription == nil || [self.localizedDNSConfigurationDescription isEqualToString:@""]) {
		if (completion) completion(@"GRDDNSHelper class property ‘localizedDNSConfigurationDescription‘ unset (nil or empty string). Please provide a user presentable configuration description");
		return;
	}
	
	[self.dnsSettingManager loadFromPreferencesWithCompletionHandler:^(NSError * _Nullable error) {
		if (error != nil) {
			if (completion) completion([NSString stringWithFormat:@"Failed to load DNS settings configuration: %@", [error localizedDescription]]);
			return;
		}
		
		NSArray <NEOnDemandRule *> *onDemandRules = self.defaultOnDemandRules;
		if (self.customOnDemandRules != nil) {
			onDemandRules = self.customOnDemandRules;
		}
		[self.dnsSettingManager setOnDemandRules:onDemandRules];
		
		
		NSString *dohHostname = kDNSFDefaultDOHHostname;
		NSURL *dohAddress;
		if (self.customDNSFHostname != nil) {
			dohHostname = self.customDNSFHostname;
		}
		dohAddress = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@/%@", dohHostname, roamingClientId]];
		
		NEDNSOverHTTPSSettings *dohSettings = [NEDNSOverHTTPSSettings new];
		[dohSettings setServerURL:dohAddress];
		[self.dnsSettingManager setDnsSettings:dohSettings];
		
		[self.dnsSettingManager saveToPreferencesWithCompletionHandler:^(NSError * _Nullable error) {
			if (error != nil) {
				if (completion) completion([NSString stringWithFormat:@"Failed to save DNS settings configuration: %@", [error localizedDescription]]);
				return;
			}
		}];
	}];
}

- (void)removeDNSSettingsConfiguration {
	if (self.dnsSettingManager == nil) {
		self.dnsSettingManager = [NEDNSSettingsManager sharedManager];
	}
	
	[GRDKeychain removeKeychainItemForAccount:kGRDKeychainStr_DNSFRoamingClientId];
	
	[self.dnsSettingManager removeFromPreferencesWithCompletionHandler:^(NSError * _Nullable error) {}];
}


@end