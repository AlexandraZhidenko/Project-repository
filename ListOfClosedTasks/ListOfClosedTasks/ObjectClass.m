//
//  ObjectClass.m
//  ListOfClosedTasks
//
//  Created by Александра Жиденко on 13.11.18.
//  Copyright © 2018 Александра Жиденко. All rights reserved.
//

#import "ObjectClass.h"

@implementation ObjectClass

-(NSString*)setSummary:(NSDictionary*)dictionary // this function defining summary task
{
    
    NSString* strSummary;
    // check if there is a comment for technical writer
    NSArray* arrWithCustomFields = [[NSArray alloc] init];
    arrWithCustomFields = [[dictionary valueForKey:@"customfields"] valueForKey:@"customfield"];
    for(int i = 0; i < arrWithCustomFields.count; i++)
    {
        if([[[[arrWithCustomFields[i] valueForKey:@"customfieldvalues"] valueForKey:@"customfieldvalue"] valueForKey:@"text"] containsString:@"href="])
        {
            strSummary = [[[arrWithCustomFields[i] valueForKey:@"customfieldvalues"] valueForKey:@"customfieldvalue"] valueForKey:@"text"];
            strSummary = [self modificationSummary:strSummary];
            return strSummary;
        }
    }
    
    NSArray* arrWithComments = [[dictionary valueForKey:@"comments"] valueForKey:@"comment"];
    // if no comments
    if (arrWithComments.count == 0)
    {
        strSummary = [[dictionary valueForKey:@"summary"] valueForKey:@"text"];
        return strSummary;
    }
    // if a few comments
    else if([arrWithComments isKindOfClass:[NSArray class]])
    {
        for(int i = 0; i < arrWithComments.count; i++)
        {
            NSString* strComment = [arrWithComments[i] valueForKey:@"text"];
            if([strComment containsString:@"</span>(<a href="])
            {
                strSummary = [self modificationSummary:strComment];
                return strSummary;
            }
        }
    }
    // if one comment
    else if([arrWithComments isKindOfClass:[NSDictionary class]])
    {
        NSString* strComment = [arrWithComments valueForKey:@"text"];
        if([strComment containsString:@"</span>(<a href="])
        {
            strSummary = [self modificationSummary:strComment];
            return strSummary;
        }
    }
    
    strSummary = [[dictionary valueForKey:@"summary"] valueForKey:@"text"];
    return strSummary;
}

-(NSString*)modificationSummary:(NSString*)str // this function return correct summary without <> br/ /p &lt &gt
{
    // from string to array
    NSMutableArray *arr = [[NSMutableArray alloc] initWithCapacity:str.length];
    for (int i=0; i < str.length; i++)
    {
        if([[str substringWithRange:NSMakeRange(i, 1)] isEqualToString:@"%"])
            [arr addObject:@"%"];
        else
        {
            NSString *tmpStr = [str substringWithRange:NSMakeRange(i, 1)];
            [arr addObject:[tmpStr stringByRemovingPercentEncoding]];
        }
    }
    
    NSUInteger lenghtDescrpt = str.length;
    NSMutableString* summary = [NSMutableString stringWithCapacity:0];
    
    for(int i = 0; i < lenghtDescrpt; i++)
    {
        if((i >= 3 && [arr[i - 2] isEqualToString:@")"] && [arr[i - 3] isEqualToString:@">"]) || (i >= 2 && [arr[i - 1] isEqualToString:@")"] && [arr[i - 2] isEqualToString:@">"]))
        {
            for(int j = i; j < lenghtDescrpt; j++)
            {
                [summary appendString:arr[j]];
                if([arr[j] isEqualToString:@"\n"] || [arr[j] isEqualToString:@"<"])
                {
                    summary = [NSMutableString stringWithString:[summary stringByReplacingOccurrencesOfString:arr[j] withString:@""]];
                    str = [str stringByReplacingOccurrencesOfString:@"<br/>" withString:@""];
                    str = [str stringByReplacingOccurrencesOfString:@"</p>" withString:@""];
                    summary = [NSMutableString stringWithString:[summary stringByReplacingOccurrencesOfString:@"&lt;" withString:@"<"]];
                    summary = [NSMutableString stringWithString:[summary stringByReplacingOccurrencesOfString:@"&gt;" withString:@">"]];
                    return summary;
                }
            }
        }
    }
    
    str = [str stringByReplacingOccurrencesOfString:@"<br/>" withString:@""];
    str = [str stringByReplacingOccurrencesOfString:@"</p>" withString:@""];
    return summary;
}

@end

@implementation Task

-(id)initWithDictionary:(NSDictionary*)dictionary
{
    self = [super init];
    
    //set status
    self.status = [[dictionary valueForKey:@"status"] valueForKey:@"text"];
    
    //set number task
    NSString* tmp = [[dictionary valueForKey:@"key"] valueForKey:@"text"];
    tmp = [tmp stringByReplacingOccurrencesOfString:@"TM-" withString:@""];
    self.numberTask = [tmp integerValue];
    
    //set parent number
    tmp = [[dictionary valueForKey:@"parent"] valueForKey:@"text"];
    tmp = [tmp stringByReplacingOccurrencesOfString:@"TM-" withString:@""];
    self.parentNumber = [tmp integerValue];
    
    //set type task
    NSString* typeStr = [[dictionary valueForKey:@"type"] valueForKey:@"text"];
    if([typeStr isEqualToString:@"Bug"])
    {
        self.type = @"#";
    }
    else if([typeStr isEqualToString:@"Task"])
    {
        self.type = @"*";
    }
    else if([typeStr isEqualToString:@"New Feature"])
    {
        self.type = @"+";
    }
    else
    {
        // NSLog(@"self number = %li",(long)self.numberTask);
        [self getParentTask];
        self.type = @"";
    }
    
    //set summary
    ObjectClass* object = [[ObjectClass alloc] init];
    
    self.summary = [object setSummary:dictionary];
    
    //set client
    NSArray* arrWithCustomFields = [[dictionary valueForKey:@"customfields"] valueForKey:@"customfield"];
    for(int j = 0; j < arrWithCustomFields.count; j++)
    {
        if([[[arrWithCustomFields[j] valueForKey:@"customfieldname"] valueForKey:@"text"] containsString:@"Client"])
        {
            self.client = YES;
            if([[[[arrWithCustomFields[j] valueForKey:@"customfieldvalues"] valueForKey:@"customfieldvalue"] valueForKey:@"text"] isEqualToString:@"TEST"])
            {
                self.typeClients = @"TEST";
                break;
            }
            else
            {
                self.typeClients = [[[[arrWithCustomFields[j] valueForKey:@"customfieldvalues"] valueForKey:@"customfieldvalue"] valueForKey:@"text"] stringByReplacingOccurrencesOfString:@"Client " withString:@""];
                break;
            }
        }
        else if(j == arrWithCustomFields.count - 1)
            self.client = NO;
    }
    
    
    return self;
}

-(void)getParentTask
{
    //NSLog(@"prev task - %li",(long)self.numberTask);
    NSString *urlString = [NSString stringWithFormat:@"%@%@%@%@%@", @"https://jira.compassplus.ru/si/jira.issueviews:issue-xml/TM-", [NSString stringWithFormat: @"%li", (long)self.parentNumber], @"/TM-", [NSString stringWithFormat: @"%li", (long)self.parentNumber], @".xml"];
    NSURL* url = [NSURL URLWithString:urlString];
    NSURLSessionConfiguration *defaultConfigObject = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *defaultSession = [NSURLSession sessionWithConfiguration:defaultConfigObject delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    NSURLSessionDataTask * dataTask = [defaultSession dataTaskWithURL:url
                                                    completionHandler:^(NSData *data, NSURLResponse *response, NSError *error){
                                                        if(error == nil)
                                                        {
                                                            NSString * text = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                                                            NSDictionary* parentsDict = [XMLReader dictionaryForXMLString:text error:&error];
                                                            if (parentsDict)
                                                            {
                                                                parentsDict = [[[parentsDict objectForKey:@"rss"] objectForKey:@"channel"] objectForKey:@"item"];
                                                                Task* parentTaskFromOtherVersion = [[Task alloc] initWithDictionary:parentsDict];
                                                                self.type = parentTaskFromOtherVersion.type;
                                                                if (_block)
                                                                {
                                                                    //NSLog(@"%ld task type - %@", self.numberTask,self.type);
                                                                    _block();
                                                                }
                                                            }
                                                            
                                                        }
                                                    }];
    [dataTask resume];
    
}

/*-(void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler
{
    // Read .p12 file
    NSString *path = @"/Users/a.zidenko/Desktop/ListOfClosedTasks/ListOfClosedTasks/cert_azh.p12";
    NSData *dataP12 = [NSData dataWithContentsOfFile:path];
    CFDataRef inP12data = (__bridge CFDataRef)dataP12;
    
    SecIdentityRef myIdentity;
    SecTrustRef myTrust;
    
    [self extractIdentityAndTrust:inP12data :&myIdentity :&myTrust];
    
    SecCertificateRef myCertificate;
    SecIdentityCopyCertificate(myIdentity, &myCertificate);
    const void *certs[] = { myCertificate };
    CFArrayRef certsArray = CFArrayCreate(NULL, certs, 1, NULL);
    
    NSURLCredential *credential = [NSURLCredential credentialWithIdentity:myIdentity certificates:(__bridge NSArray*)certsArray persistence:NSURLCredentialPersistencePermanent];
    completionHandler(NSURLSessionAuthChallengeUseCredential, credential);
}

-(OSStatus*)extractIdentityAndTrust:(CFDataRef)inP12data :(SecIdentityRef*)identity :(SecTrustRef*)trust
{
    // Import .p12 data
    CFStringRef password = CFSTR("qwerty");
    const void *keys[] = { kSecImportExportPassphrase };
    const void *values[] = { password };
    CFDictionaryRef options = CFDictionaryCreate(NULL, keys, values, 1, NULL, NULL); // options = {passphrase = password;}
    
    CFArrayRef keyref = NULL;
    OSStatus sanityChesk = SecPKCS12Import(inP12data, options, &keyref);
    
    if(sanityChesk == 0)
    {
        //NSLog(@"Success opening p12 certificate.");
        CFDictionaryRef myIdentityAndTrust = CFArrayGetValueAtIndex(keyref, 0);
        const void *tempIdentity = CFDictionaryGetValue(myIdentityAndTrust, kSecImportItemIdentity);
        *identity = (SecIdentityRef)tempIdentity;
        const void *tempTrust = CFDictionaryGetValue(myIdentityAndTrust, kSecImportItemTrust);
        *trust = (SecTrustRef)tempTrust;
    }
    else
        NSLog(@"Error %d", sanityChesk);
    
    return sanityChesk;
}*/

-(void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler
{
    NSString* tmpFilePath = @"/Users/a.zidenko/Desktop/ListOfClosedTasks/ListOfClosedTasks/cert.p12";
    NSData* cert = [[NSData alloc] initWithContentsOfFile:tmpFilePath];
    CFDataRef inP12data = (__bridge CFDataRef)cert;
    SecIdentityRef myIdentity;
    SecTrustRef myTrust;
    
    [self extractIdentityAndTrust:inP12data :&myIdentity :&myTrust];
    
    SecCertificateRef myCertificate;
    SecIdentityCopyCertificate(myIdentity, &myCertificate);
    const void *certs[] = { myCertificate };
    CFArrayRef certsArray = CFArrayCreate(NULL, certs, 1, NULL);
    
    NSURLCredential *credential = [NSURLCredential credentialWithIdentity:myIdentity certificates:(__bridge NSArray*)certsArray persistence:NSURLCredentialPersistencePermanent];
    completionHandler(NSURLSessionAuthChallengeUseCredential, credential);
}

-(OSStatus*)extractIdentityAndTrust:(CFDataRef)inP12data :(SecIdentityRef*)identity :(SecTrustRef*)trust
{
    // Import .p12 data
    CFStringRef password = (__bridge CFStringRef)(self.password);
    const void *keys[] = { kSecImportExportPassphrase };
    const void *values[] = { password };
    CFDictionaryRef options = CFDictionaryCreate(NULL, keys, values, 1, NULL, NULL); // options = {passphrase = password;}
    
    CFArrayRef keyref = NULL;
    
    OSStatus sanityChesk = SecPKCS12Import(inP12data, options, &keyref);
    
    if(sanityChesk == errSecSuccess)
    {
        NSLog(@"Success opening p12 certificate.");
        CFDictionaryRef myIdentityAndTrust = CFArrayGetValueAtIndex(keyref, 0);
        const void *tempIdentity = CFDictionaryGetValue(myIdentityAndTrust, kSecImportItemIdentity);
        *identity = (SecIdentityRef)tempIdentity;
        const void *tempTrust = CFDictionaryGetValue(myIdentityAndTrust, kSecImportItemTrust);
        *trust = (SecTrustRef)tempTrust;
    }
    else
        NSLog(@"err %d", sanityChesk);
    
    return sanityChesk;
}

@end

