//
//  DHReRAM.h
//  e-HReRAM
//  Dynamic Hybrid Reconfigurable ReRAM
//  Created by Miguel Lastras on 5/6/15.
//  Copyright (c) 2015 Miguel Lastras. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HPTable.h"
#import "GlobalFunctions.h"
#import "GlobalDefinitions.h"
#import "InterfaceProtocol.h"

#define ALLOCATED_MASK 0x8000000000000000

struct Page
{
  BOOL memristiveMode;
  BOOL valid;
  BOOL dirty;
  unsigned long int recentAccessCount;
  unsigned long int timeStamp;
  unsigned long int *toggleCounters;
  unsigned long int associatedPageAddress;
};

struct Block
{
  unsigned long int k;
  unsigned long int a; // differential block access counter
  unsigned long int r; // differential block read (byte) counter
  unsigned long int w; // differential block write (byte) counter
  unsigned long int d; // differential block deactivation (byte) counter
//  unsigned long int t;
  struct Page *pages;
};

struct MegaBlock
{
  unsigned long int nextAvailableBlock; // Ever increasing counter. Must be masked to take the LSBs
  struct Block *blocks;
};

@interface DHReRAM : NSObject <InterfaceProtocol> {
  HPTable *pageTable;
  struct MegaBlock megaBlock;
  unsigned long int accessCount;
  unsigned long int accessCount_diff; // differential counter (reset every time energy is computed)
  unsigned long int pageSize;
  unsigned long int blockSize;
  unsigned long int memoryBlockSize;
  unsigned long int megaBlockSize;
  unsigned long int capacityInBytes;
  unsigned long int pageSizeBits;
  unsigned long int memoryBlockSizeBits;
  unsigned long int megaBlockSizeBits;
  unsigned long int evictionCount;
  unsigned long int hits;
  unsigned long int mHits;
  unsigned long int mHits_diff; // differential counter (reset every time energy is computed)
  unsigned long int misses;
  unsigned long int mMisses;
  unsigned long int mMisses_diff; // differential counter (reset every time energy is computed)
  unsigned long int readPenalty;
  unsigned long int writePenalty;
  unsigned long int loadFromCRSPenalty;
  unsigned long int loadFromMemristorPenalty;
  unsigned long int deactivationPenalty;
  unsigned long int *kMap;
  unsigned long int *aMap;
  unsigned long int *tCountByPage;
  unsigned long int *tCountByByte;
  unsigned long int pages;
  unsigned long int bytes;
  NSString *name;
  char memoryCapacity[32];
  id next;
  BOOL hybridEnabled;
  BOOL crsOnlyEnabled;
  BOOL dynamicAllocationEnabled;
}

@property (nonatomic, readonly) unsigned long int blockSize;
@property (nonatomic, readonly) unsigned long int megaBlockSize;
@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) unsigned long int pages;
@property (nonatomic, readonly) unsigned long int bytes;
@property (nonatomic, readonly) unsigned long int accessCount;
@property (nonatomic, readonly) unsigned long int hits;
@property (nonatomic, readonly) unsigned long int misses;
@property (nonatomic, readonly) unsigned long int mHits;
@property (nonatomic, readonly) unsigned long int mMisses;



- (id) initWithPageSize:(unsigned long int)aPageSize
          pagesPerBlock:(unsigned long int)aMemoryBlockSize
     blocksPerMegaBlock:(unsigned long int)aMegaBlockSize
              nextLevel:(id)theNext
                   Name:(NSString*)theName
                CRSOnly:(BOOL)crsOnly
                 hybrid:(BOOL)hybrid
               initialK:(unsigned long int)initialK
      dynamicAllocation:(BOOL)dynamicAllocation;

// Public interface for read/write into the memory
- (void) accessBlock:(unsigned long int)address
              ofSize:(unsigned long int)size
       readOperation:(BOOL)read;

/* Description:
 Returns ULONG_MAX if the insertion did not produce
 an eviction, i.e., there was a position available
 in the set either because a position was 'invalid' or
 because a valid position was 'not dirty'. Otherwise it
 returns the 'tag' of the evicted block. The eviction is
 selected based on the timeStamp of the tag. Note that
 ULONG_MAX is not a valid value for a tag.
 In both cases after the tag is succesfully inserted,
 its 'valid' bit is asserted and its timeStamp is updated
 Note that its 'dirty' bit is left untouched. It should
 be handled outside this function. */


/* Description: 
 Returns YES if the update produces an eviction. 
 Otherwise returns NO.
 In any case, the valid bit is asserted, the timeStamp
 is updated. */
- (BOOL) validateAndCheckForEvictionOn:(struct Page*)aPage;

// Functions to increase and decrease the access counters
- (void) increaseAccessCounterOn:(unsigned long int*)address;
- (void) decreaseAccessCounterOn:(unsigned long int*)address;

- (unsigned long int*) computeToggleByPage;
- (unsigned long int*) computeToggleByByte;

- (unsigned long int*) kMap;

- (void) releaseMemory;

- (NSString*) memoryCapacity;

- (double) memristiveFraction;

- (void) deactivateUnsedBlocks;

- (unsigned long int) getBlockID;

- (unsigned long int) getPageIDfromBlock:(struct Block*)block;

- (void) updatePageToggleOnPage:(struct Page*)aPage;

- (void) resetAccessCounters;

- (struct EnergyBundle) getEnergyConsumption;

- (void) updateToggleOnPage:(struct Page*)aPage
                 withOffset:(unsigned long int)offset
                     ofSize:(unsigned long int)size
                 withAmount:(unsigned long int)amount;



@end
