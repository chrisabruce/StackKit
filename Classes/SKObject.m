//
//  SKObject.m
//  StackKit
//
//  Created by Dave DeLong on 12/30/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <StackKit/SKObject_Internal.h>
#import <objc/runtime.h>

@implementation SKObject {
    // _info will be either an NSDictionary or NSManagedObject, depending on the subclass
    // either way, it'll respond to -valueForKey:
    id _info;
}

+ (id)allocWithZone:(NSZone *)zone {
    [NSException raise:NSInternalInconsistencyException format:@"You may not allocate instances of %@", NSStringFromClass(self)];
    return nil;
}

+ (NSString *)_infoKeyForSelector:(SEL)selector {
    return NSStringFromSelector(selector);
}

+ (id)_transformValue:(id)value forReturnType:(Class)returnType {
    return value;
}

+ (BOOL)resolveInstanceMethod:(SEL)sel {
    // wooo handle the @dynamic properties!
    objc_property_t property = class_getProperty(self, sel_getName(sel));
    if (property == NULL) { return NO; }
    
    NSString *key = [self _infoKeyForSelector:sel];
    
    char *value = property_copyAttributeValue(property, "T");
    int length = strlen(value);
    Class returnType = [NSString class];
    if (length > 3) {
        // the type is of the form @"ClassName"
        // this will create a string skipping the leading @" and trailing "
        NSString *className = [[NSString alloc] initWithBytes:value+2 length:length-3 encoding:NSUTF8StringEncoding];
        returnType = NSClassFromString(className);
        [className release];
    }
    
    id(^impBlock)(SKObject *) = ^(SKObject *_s){
        id value = [_s _valueForInfoKey:key];
        value = [[_s class] _transformValue:value forReturnType:returnType];        
        return value;
    };
    
    IMP newIMP = imp_implementationWithBlock((void *)impBlock);
    class_addMethod(self, sel, newIMP, "@@:");
    
    return YES;
}

- (id)_initWithInfo:(id)info {
    self = [super init];
    if (self) {
        _info = [info retain];
    }
    return self;
}

- (void)dealloc {
    [_info release];
    [super dealloc];
}

- (id)_valueForInfoKey:(NSString *)key {
    return [_info valueForKey:key];
}

- (NSString *)debugDescription {
    return [NSString stringWithFormat:@"%@ %@", [super description], _info];
}

@end
