//  if( read ) printf("%s(%f): Reading address %lu ", [name UTF8String], [self activeFraction], address);
//  else printf("%s(%f): Writing on address %lu ", [name UTF8String], [self activeFraction], address);  
//      printf("%s: Evicting block with address %lu\n", [name UTF8String], evictedBlockAddress );
/*
 * HReRAM.m
 * Hybrid Reconfigurable Resistive RAM
 *
 * Created by Miguel Lastras on Feb 24, 2015
 */

#import "HReRAM.h"

@implementation HReRAM

@synthesize name;
@synthesize memCache;
@synthesize eCounters;

- (void) accessAddress:(unsigned long int)address
         readOperation:(BOOL)read
{
  memCache.accessCount++;
  unsigned long int index = (address & memCache.indexMask) >> memCache.indexOffset;
  unsigned long int tag = address >> memCache.tagOffset;

  [eCounters allocateSelectAddress:address]; // prepare terrain in hash table...

  // first take care of fully memristive/CRS cases
  if( CRSOnly ){ // fully CRS case:
    if( read )
      [eCounters increaseByteEnduranceBy:SINGLE];
    else // it's a write
      [eCounters increaseByteEnduranceBy:(DELTA/2)];
  }
  else if ( !hybridEnabled ){ // fully memristive case:
    if( read )
      [eCounters increaseByteEnduranceBy:0];
    else // it's a write
      [eCounters increaseByteEnduranceBy:SINGLE/2];
  }
  
  // now manage the cache misses and the CRS <-> Memristor (de)activations
  if( [memCache lookupTag:tag onSet:memCache.tagArray[index]] ){ // we got a hit :)
    memCache.hits++;
    [memCache updateTag:tag onSet:memCache.tagArray[index]];

    if( hybridEnabled ){
      if( read )
        [eCounters increaseByteEnduranceBy:0];
      else
        [eCounters increaseByteEnduranceBy:SINGLE/2];
    }
  }
  else{ // we got a miss :(
    memCache.misses++;
    [next accessAddress:address readOperation:YES]; // bring the block from the next level
    unsigned long int evictedTag = [memCache insertTag:tag onSet:memCache.tagArray[index]]; // insert it
    

    if( hybridEnabled ){
      if( read )
        [eCounters increasePageEnduranceBy:(DELTA+SINGLE)/2];
      else
        [eCounters increasePageEnduranceBy:(DELTA+SINGLE)/2];
    }

    // handle the possible eviction
    if( evictedTag != ULONG_MAX ){
      unsigned long int evictedBlockAddress = evictedTag << memCache.tagOffset | (index << memCache.indexOffset);
      [eCounters allocateSelectAddress:evictedBlockAddress];
      [next writeBackBlock:evictedBlockAddress ofSize:memCache.blockSize]; // write back the eviction
      if( hybridEnabled )
        [eCounters increasePageEnduranceBy:(DELTA+SINGLE)/2];
    }
  }
}

- (id) initWithSetsBits:(unsigned long int)sb
      associativityBits:(unsigned long int)ab
      bytesPerBlockBits:(unsigned long int)bb
              nextLevel:(id)theNext
                   name:(NSString*)theName
                CRSOnly:(BOOL)crsOnly
                 hybrid:(BOOL)hybrid;
{
  self = [super init];
  if(self != nil){
    assert( !(crsOnly&hybrid) ); // cannot be crsOnly and hybrid at the same time
    name = theName;
    CRSOnly = crsOnly;
    hybridEnabled = hybrid;
    unsigned long int b4 = ceil((double)(ADDRESS_SPACE-bb)/3.0);
    unsigned long int b3 = round((double)(ADDRESS_SPACE-bb)/3.0);
    unsigned long int b2 = floor((double)(ADDRESS_SPACE-bb)/3.0);
    unsigned long int b1 = bb;
    eCounters = [[HHTable alloc] initWithB4:b4 b3:b3 b2:b2 b1:b1];
    memCache = [[SACache alloc] initWithSetsBits:sb associativityBits:ab bytesPerBlockBits:bb nextLevel:nil name:[theName stringByAppendingString:@" Cache"]];
    next = theNext;
  }
  return self;
}

- (void) printCapacity
{
  [memCache printCapacity];
}

- (void) releaseMemory
{
  [eCounters releaseMemory];
  [memCache releaseMemory];
}

// Returns the active fraction of the cache
- (double) activeFraction
{
  unsigned long int availablePositions = memCache.sets * memCache.associativity;
  unsigned long int occupiedPositions = 0;
  for( int i=0; i<memCache.sets; i++ )
    for( int j=0; j<memCache.associativity; j++ )
      if(memCache.tagArray[i][j] != ULONG_MAX)
        occupiedPositions++;
  return (double) occupiedPositions/availablePositions;
}

@end
