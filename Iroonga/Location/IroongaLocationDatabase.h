//
//  IroongaLocationDatabase.h
//
//  Created by goccy on 2015/09/06.
//  Copyright (c) 2015年 goccy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IroongaLocationTable.h"

@interface IroongaLocationDatabase : NSObject

@property(nonatomic) NSString *name;

- (instancetype)initWithName:(NSString *)name;
+ (instancetype)createWithName:(NSString *)name;
- (void)drop;
- (BOOL)isAlreadyCreated;
- (IroongaLocationTable *)createTableWithName:(NSString *)name;
- (IroongaLocationTable *)tableWithName:(NSString *)name indexColumnName:(NSString *)columnName;

@end
