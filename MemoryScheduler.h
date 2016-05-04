//
//  MemoryScheduler.h
//  e-HReRAM
//
//  Created by Miguel Lastras on 5/5/15.
//  Copyright (c) 2015 Miguel Lastras. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HPTable.h"
#import "SACacheX.h"
#import "GlobalFunctions.h"

@interface MemoryScheduler : NSObject{
  unsigned long int setsBits;
  unsigned long int sets;
  unsigned long int blockSizeBits;
  unsigned long int blockSize;
  unsigned long int associativity;
  unsigned long int associativityBits;
  unsigned long int *kMap;
  unsigned long int *aMap;
  unsigned long int *tMap;
  unsigned long int numEntries;
  HPTable *hashTable;
  NSString *name;
  id next;
}

@property (nonatomic, readonly) unsigned long int *kMap;
@property (nonatomic, readonly) unsigned long int *aMap;
@property (nonatomic, readonly) unsigned long int *tMap;
@property (nonatomic, readonly) unsigned long int sets;
@property (nonatomic, readonly) unsigned long int blockSize;
@property (nonatomic, readonly) NSString *name;

- (void) accessBlock:(unsigned long int)address
              ofSize:(unsigned long int)size
       readOperation:(BOOL)read;

- (id) initWithNextLevel:(id)theNext
                    name:(NSString*)theName;

- (unsigned long int) getIndexWithHint:(unsigned long int)hint;

- (void) printCapacity;
- (void) releaseMemory;

@end
