//
//  MemoryScheduler.m
//  e-HReRAM
//
//  Created by Miguel Lastras on 5/5/15.
//  Copyright (c) 2015 Miguel Lastras. All rights reserved.
//

#import "MemoryScheduler.h"

@implementation MemoryScheduler

@synthesize kMap;
@synthesize aMap;
@synthesize tMap;
@synthesize sets;
@synthesize name;
@synthesize blockSize;

- (id) initWithNextLevel:(id)theNext
                    name:(NSString*)theName
{
  self = [super init];
  if( self != nil ){
    name = theName;
    next = theNext;
    setsBits = [next setsBits];
    blockSizeBits = [next blockSizeBits];
    associativityBits = [next associativityBits];
    sets = 1UL << setsBits;
    blockSize = 1UL << blockSizeBits;
    associativity = 1UL << associativityBits;
    hashTable = [[HPTable alloc] initWithB3:12 b2:12 b1:12];
    kMap = (unsigned long int*) malloc( sizeof(unsigned long int)*sets );
    aMap = (unsigned long int*) malloc( sizeof(unsigned long int)*sets );
    tMap = (unsigned long int*) malloc( sizeof(unsigned long int)*sets );
    for(int i=0; i<sets; i++){
      kMap[i] = 0;
      aMap[i] = 0;
      tMap[i] = 0;
    }
    numEntries = 0;
  }
  return self;
}

- (void) accessBlock:(unsigned long int)address
              ofSize:(unsigned long int)size
       readOperation:(BOOL)read
{
  unsigned long int offset = address & (blockSize-1UL);
  unsigned long int blockAddress = address >> blockSizeBits;
  unsigned long int mappedBlockAddress = [hashTable getKeyOnAddress:blockAddress];
  unsigned long int mappedAddress;
  
  // check if the translation has been made:
  if( mappedBlockAddress ){
    mappedAddress = (mappedBlockAddress<<blockSizeBits)|offset; // construct mapped address
    [next accessBlock:mappedAddress ofSize:size readOperation:read]; // forward address to the next level
    return;
  }
  
  // translation has not been made, then we need to find a good candidate based on k/a/t maps
  unsigned long int index = [self getIndexWithHint:(blockAddress&(sets-1UL))];
  mappedBlockAddress = (blockAddress & (~(sets-1UL))) | index; // reconstruct block address
  mappedAddress = (mappedBlockAddress<<blockSizeBits) | offset; // reconstruct whole address
  
  // Insert translation in hash table
  [hashTable insertKey:mappedBlockAddress];
  
  [next accessBlock:mappedAddress ofSize:size readOperation:read]; // forward address to the next level
}

- (unsigned long int) getIndexWithHint:(unsigned long int)hint
{
  unsigned long int returnIndex;
  returnIndex = (hint+10)%sets;
//  returnIndex = (hint*hint)%sets;
  returnIndex = hint;
//  returnIndex = (numEntries++)%sets; // simple round robin scheme

  kMap[returnIndex]++;
  return returnIndex;
}

- (void) printCapacity
{
  printf(" -** %s **-\n", [name UTF8String]);
}

- (void) releaseMemory
{
  free(kMap);
  free(aMap);
  free(tMap);
  [hashTable releaseMemory];
}

@end
