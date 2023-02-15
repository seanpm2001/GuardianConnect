//
//  GRDAPIError.m
//  GuardianConnect
//
//  Created by Constantin Jacob on 08.02.23.
//  Copyright © 2023 Sudo Security Group Inc. All rights reserved.
//

#import "GRDAPIError.h"

@implementation GRDAPIError

- (NSString *)description {
	return [NSString stringWithFormat:@"Error-Title: %@ Error-Message: '%@'", self.title, self.message];
}

- (instancetype)initWithData:(NSData *)jsonData {
	self = [super init];
	if (self) {
		NSError *jsonErr;
		self.apiErrorDictionary = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&jsonErr];
		if (jsonErr != nil) {
			self.parseError = jsonErr;
			
		} else {
			self.title 		= [self.apiErrorDictionary objectForKey:@"error-title"];
			self.message 	= [self.apiErrorDictionary objectForKey:@"error-message"];
		}
	}
	
	return self;
}

@end