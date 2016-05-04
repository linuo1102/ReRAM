/*
 * MemristiveRAM.m
 * Memristive RAM
 *
 * Created by Miguel Lastras on Apr 16, 2015
 */

#import "MemristiveRAM.h"

@implementation MemristiveRAM

@synthesize name;
@synthesize memCache;
@synthesize eCounters;

- (void) accessBlock:(unsigned long int)address
              ofSize:(unsigned long int)size
       readOperation:(BOOL)read
{
  memCache.accessCount++;
  unsigned long int blockAddress = address & memCache.blockAddressMask;
  unsigned long int index = (address & memCache.indexMask) >> memCache.indexOffset;
  unsigned long int tag = address >> memCache.tagOffset;
  
  [eCounters allocateSelectAddress:address]; // prepare terrain in hash table...
  
  if( read )
    [eCounters increaseBlockEnduranceOfSize:size withAmount:0];
  else // it's a write
    [eCounters increaseBlockEnduranceOfSize:size withAmount:SINGLE/2];
  
  if( [memCache lookupTag:tag onSet:memCache.tagArray[index]] ){ // we got a hit :)
    memCache.hits++;
    [memCache updateTag:tag onSet:memCache.tagArray[index]];
  }
  else{ // we got a miss :(
    memCache.misses++;
    [next accessBlock:blockAddress ofSize:memCache.blockSize readOperation:YES]; // bring the block from the next level
    unsigned long int evictedTag = [memCache insertTag:tag onSet:memCache.tagArray[index]]; // insert it
    
    // handle the possible eviction
    if( evictedTag != ULONG_MAX ){
      unsigned long int evictedBlockAddress = evictedTag << memCache.tagOffset | (index << memCache.indexOffset);
      [eCounters allocateSelectAddress:evictedBlockAddress]; // ...............Is it needed?
      [next accessBlock:evictedBlockAddress ofSize:memCache.blockSize readOperation:NO]; // write back the eviction
    }
  }
}

- (unsigned long int) blockSize
{
  return memCache.blockSize;
}

- (id) initWithSetsBits:(unsigned long int)sb
      associativityBits:(unsigned long int)ab
      bytesPerBlockBits:(unsigned long int)bb
              nextLevel:(id)theNext
                   name:(NSString*)theName;
{
  self = [super init];
  if(self != nil){
    name = theName;
    next = theNext;
    unsigned long int b4 = ceil((double)(ADDRESS_SPACE-bb)/3.0);
    unsigned long int b3 = round((double)(ADDRESS_SPACE-bb)/3.0);
    unsigned long int b2 = floor((double)(ADDRESS_SPACE-bb)/3.0);
    unsigned long int b1 = bb;
    eCounters = [[HHTable alloc] initWithB4:b4 b3:b3 b2:b2 b1:b1];
    memCache = [[SACache alloc] initWithSetsBits:sb
                               associativityBits:ab
                               bytesPerBlockBits:bb
                                       nextLevel:nil
                                            name:[theName stringByAppendingString:@" Cache"]];
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
