//
//  DHReRAM.m
//  e-HReRAM
//  Dynamic Hybrid Reconfigurable ReRAM
//  Created by Miguel Lastras on 5/6/15.
//  Copyright (c) 2015 Miguel Lastras. All rights reserved.
//

#import "DHReRAM.h"

@implementation DHReRAM

@synthesize blockSize;
@synthesize megaBlockSize;
@synthesize name;
@synthesize pages;
@synthesize bytes;
@synthesize accessCount;
@synthesize hits;
@synthesize misses;
@synthesize mHits;
@synthesize mMisses;

- (id) initWithPageSize:(unsigned long int)aPageSize
          pagesPerBlock:(unsigned long int)aMemoryBlockSize
     blocksPerMegaBlock:(unsigned long int)aMegaBlockSize
              nextLevel:(id)theNext
                   Name:(NSString*)theName
                CRSOnly:(BOOL)crsOnly
                 hybrid:(BOOL)hybrid
               initialK:(unsigned long int)initialK
      dynamicAllocation:(BOOL)dynamicAllocation
{
  self = [super init];
  if( self != nil ){
    next = theNext;
    evictionCount = 0;
    hits = 0;
    misses = 0;
    mHits = 0;
    mMisses = 0;
    mHits_diff = 0;
    mMisses_diff = 0;
    accessCount = 0;
    accessCount_diff = 0;
    pageSize = aPageSize;
    blockSize = aPageSize;
    memoryBlockSize = aMemoryBlockSize;
    megaBlockSize = aMegaBlockSize;
    pages = memoryBlockSize * megaBlockSize;
    bytes = pages*pageSize;
    capacityInBytes = pageSize*pages;
    pageSizeBits = [GlobalFunctions log2floor:pageSize];
    memoryBlockSizeBits = [GlobalFunctions log2floor:memoryBlockSize];
    megaBlockSizeBits = [GlobalFunctions log2floor:megaBlockSize];
    name = theName;
    hybridEnabled = hybrid;
    crsOnlyEnabled = crsOnly;
    dynamicAllocationEnabled = dynamicAllocation;
    // Init the memory:
    megaBlock.blocks = (struct Block*) malloc( sizeof(struct Block) * megaBlockSize );
    megaBlock.nextAvailableBlock = 0;
    for( unsigned long int i = 0; i<megaBlockSize; i++ ){
      megaBlock.blocks[i].pages = (struct Page*) malloc( sizeof(struct Page) * memoryBlockSize );
/*      if(crsOnly)
        megaBlock.blocks[i].k = 0; // FULLY CRS
      else if(hybrid)
        megaBlock.blocks[i].k = initialK; // HYBRID
      else
        megaBlock.blocks[i].k = memoryBlockSize; // FULLY MEMRISTIVE*/
      megaBlock.blocks[i].k = initialK; // Treat all cases as if they were in the hybrid mode (will give uniformity in the comparisons)
      megaBlock.blocks[i].a = 0;
      megaBlock.blocks[i].d = 0;
      megaBlock.blocks[i].r = 0;
      megaBlock.blocks[i].w = 0;
      for( unsigned long int j = 0; j<memoryBlockSize; j++ ){
        megaBlock.blocks[i].pages[j].toggleCounters = (unsigned long int*) malloc( sizeof(unsigned long int) * pageSize );
        if(crsOnly) megaBlock.blocks[i].pages[j].memristiveMode = NO;
        else if(hybrid){
          if( j < megaBlock.blocks[i].k )
            megaBlock.blocks[i].pages[j].memristiveMode = YES;
          else
            megaBlock.blocks[i].pages[j].memristiveMode = NO;
        }
        else megaBlock.blocks[i].pages[j].memristiveMode = YES;
//        megaBlock.blocks[i].pages[j].estimatedToggleCount = 0;
        megaBlock.blocks[i].pages[j].associatedPageAddress = ~0;
        megaBlock.blocks[i].pages[j].timeStamp = 0;
        megaBlock.blocks[i].pages[j].recentAccessCount = 0;
        megaBlock.blocks[i].pages[j].valid = NO; // The memory is initially empty
        megaBlock.blocks[i].pages[j].dirty = NO;
        for( unsigned long int k = 0; k<pageSize; k++ )
          megaBlock.blocks[i].pages[j].toggleCounters[k] = 0; // Init the toggle counters
      }
    }
    
    if( crsOnly ){
      readPenalty = SINGLE;
      writePenalty = DELTA/2;
      loadFromCRSPenalty = DELTA/2;
      loadFromMemristorPenalty = DELTA/2; // this case shouldn't use this penalty
      deactivationPenalty = 0; // shouldn't be used
    } else if( hybrid ){
      readPenalty = 0;
      writePenalty = SINGLE/2;
      loadFromCRSPenalty = (DELTA+SINGLE)/2;
      loadFromMemristorPenalty = SINGLE/2;
      deactivationPenalty = (DELTA+SINGLE)/2;
    } else{
      readPenalty = 0;
      writePenalty = SINGLE/2;
      loadFromCRSPenalty = SINGLE/2; // this case shouldn't use this penalty
      loadFromMemristorPenalty = SINGLE/2;
      deactivationPenalty = 0; // shouldn't be used
    }
    
    // Init the page translation table
    pageTable = [[HPTable alloc] initWithB3:12 b2:12 b1:12];
    
  }
  return self;
}

- (void) readAddress:(unsigned long int)address
              ofSize:(unsigned long int)size
{
  // implement read operation here
}

- (void) writeAddress:(unsigned long int)address
              ofSize:(unsigned long int)size
{
  // implement write operation here
}

- (void) accessBlock:(unsigned long int)address
              ofSize:(unsigned long int)size
       readOperation:(BOOL)read
{
  accessCount++;
  accessCount_diff++;
  unsigned long int pageAddress = address >> pageSizeBits;
  unsigned long int blockAddress = pageAddress << pageSizeBits;
  unsigned long int offset = address & (pageSize-1UL);
  unsigned long int map = [pageTable getKeyOnAddress:pageAddress];
  unsigned long int blockID;
  unsigned long int pageID;
  
  if( map & ALLOCATED_MASK ){ // this is a 'page hit'
    hits++;
    blockID = (map & (~ALLOCATED_MASK)) >> memoryBlockSizeBits;
    pageID = map & (memoryBlockSize-1UL);
    
    if( (!(megaBlock.blocks[blockID].pages[pageID].memristiveMode)) && hybridEnabled ) // if page in CRS, update kMap (this optimizes endurance, not power)
      megaBlock.blocks[blockID].k++;
    megaBlock.blocks[blockID].a++; // update the access counter of the block
    
    // udpate (the global) memristive hit counters (on cache hit)
    if( megaBlock.blocks[blockID].pages[pageID].memristiveMode ){
      mHits++;
      mHits_diff++;
    }
    else{ // block is in CRS mode
      mMisses++;
      mMisses_diff++;
    }
    
    // Now, actually perform the operation:
    if( read ){
      [self updateToggleOnPage:&megaBlock.blocks[blockID].pages[pageID] withOffset:offset ofSize:size withAmount:readPenalty]; // Endurance
      megaBlock.blocks[blockID].r += size; // Energy
    }
    else{ // ( write )
      [self updateToggleOnPage:&megaBlock.blocks[blockID].pages[pageID] withOffset:offset ofSize:size withAmount:writePenalty]; // Endurance
      megaBlock.blocks[blockID].pages[pageID].dirty = YES;
      megaBlock.blocks[blockID].w += size; // Energy
    }
  }
  else{ // a page fault!
    misses++;
    [next accessBlock:blockAddress ofSize:blockSize readOperation:YES]; // bring the whole block from the next level
    // the previous operation will result in a write in the whole block (page size),
    // which should increase the energy and age of the whole page. This is paid in (@*@)
    
    // find a good candidate position for insertion
    if(dynamicAllocationEnabled){
      blockID = [self getBlockID];
      pageID = [self getPageIDfromBlock:&megaBlock.blocks[blockID]];
    }
    else{
      // Static Smart Way:
      //blockID = (address >> pageSizeBits) & (megaBlockSize-1UL);
      //pageID = (address >> (pageSizeBits+megaBlockSizeBits)) & (memoryBlockSize-1UL);
      
      // Static Dumb Way:
      //blockID = (address >> (pageSizeBits+memoryBlockSizeBits)) & (megaBlockSize-1UL);
      //pageID = (address >> pageSizeBits) & (memoryBlockSize-1UL);
      
      // Static Random Way:
      blockID = rand()%megaBlockSize;
      pageID = rand()%memoryBlockSize;
      

      // Force a fixed fraction
      //pageID = 0;
      
      // Actually find a good page
      //pageID = [self getPageIDfromBlock:&megaBlock.blocks[blockID]];
    }
    
    // with this new position, construct key for next memory accesses in the hash table
    unsigned long int key = ((blockID << memoryBlockSizeBits) | pageID) | ALLOCATED_MASK;
    [pageTable insertKey:key];  // insert mapping in hash table
    
    if( (!(megaBlock.blocks[blockID].pages[pageID].memristiveMode)) && hybridEnabled ) // if page in CRS, update kMap
      megaBlock.blocks[blockID].k++;
    megaBlock.blocks[blockID].a++; // update the access counter of the block
    
    // if the page selected by pageID is invalid, validate it.
    // also check for an eviction will be produced (because the selected page
    //  was valid and it was dirty)
    BOOL evictionNecessary = [self validateAndCheckForEvictionOn:&megaBlock.blocks[blockID].pages[pageID]];
    
    // udpate (the global) memristive hit counters (on cache miss)
    if( megaBlock.blocks[blockID].pages[pageID].memristiveMode ){
      mHits++;
      mHits_diff++;
    }
    else{ // block is in CRS mode
      mMisses++;
      mMisses_diff++;
    }
    
    // (@*@):
    // Pay the penalty due to the load
    [self updatePageToggleOnPage:&megaBlock.blocks[blockID].pages[pageID]]; // increase toggle in the whole page due to the load (Endurance)
    megaBlock.blocks[blockID].w += blockSize; // load penalty (Energy)
    
    // handle the possible eviction
    if( evictionNecessary ){
      
      // Pay the penalty of reading the evicted block:
      [self updateToggleOnPage:&megaBlock.blocks[blockID].pages[pageID] withOffset:0 ofSize:blockSize withAmount:readPenalty]; // Endurance
      megaBlock.blocks[blockID].r += blockSize; // Energy
      
      evictionCount++;
      
      // invalidate the evicted's map in the pageTable
      unsigned long int evictedPageAddress = megaBlock.blocks[blockID].pages[pageID].associatedPageAddress;
      [pageTable invalidateKeyOnAddress:evictedPageAddress];
      
      [next accessBlock:evictedPageAddress ofSize:blockSize readOperation:NO]; // write back the eviction to the next level
    }
    
    // After the possible eviction is performed, update associatedPageAddress
    megaBlock.blocks[blockID].pages[pageID].associatedPageAddress = pageAddress; // for reverse physical->virtual address translation
    
    // Now, actually perform the operation:
    if( read ){
      [self updateToggleOnPage:&megaBlock.blocks[blockID].pages[pageID] withOffset:offset ofSize:size withAmount:readPenalty];
      megaBlock.blocks[blockID].pages[pageID].dirty = NO;
      megaBlock.blocks[blockID].r += size;
    }
    else{
      [self updateToggleOnPage:&megaBlock.blocks[blockID].pages[pageID] withOffset:offset ofSize:size withAmount:writePenalty];
      megaBlock.blocks[blockID].pages[pageID].dirty = YES;
      megaBlock.blocks[blockID].w += size;
    }
  }
}

- (BOOL) validateAndCheckForEvictionOn:(struct Page*)aPage
{
  aPage->timeStamp = GlobalTime;
  if( !aPage->valid ){ // if invalid
    aPage->valid = YES;
    return NO;
  }
  // Page is valid
  if( !aPage->dirty ){ // if not dirty
    return NO;
  }
  return YES; // because the page was valid and dirty
}

- (unsigned long int) getPageIDfromBlock:(struct Block*)block
{
  // Priority list:
    // 1. Invalid/Memristive
    // 2. Invalid/CRS
    // 3. Valid/Memristive
    // 4. Valid/CRS
  
  // Invalid/Memristive
  for(unsigned long int pos=0; pos<memoryBlockSize; pos++)
    if( ((block->pages[pos].memristiveMode)) && (!(block->pages[pos].valid)) )
      return pos;
  
  // Invalid/CRS
  for(unsigned long int pos=0; pos<memoryBlockSize; pos++)
    if( (!(block->pages[pos].memristiveMode)) && (!(block->pages[pos].valid)) )
      return pos;
  
  // Valid/Memristive
  for(unsigned long int pos=0; pos<memoryBlockSize; pos++)
    if( ((block->pages[pos].memristiveMode)) && ((block->pages[pos].valid)) )
      return pos;
  
  // Valid/CRS
  for(unsigned long int pos=0; pos<memoryBlockSize; pos++)
    if( (!(block->pages[pos].memristiveMode)) && ((block->pages[pos].valid)) )
      return pos;
  
  assert(0); // Should never reach this condition
}

- (unsigned long int) getBlockID
{
  // Perform a reverse search looking for the block with the minimum k
  unsigned long int blockID = 0; // this is not necessary
  unsigned long int k = memoryBlockSize; // worst case
  unsigned long int pos = (megaBlock.nextAvailableBlock)&(megaBlockSize-1UL); // consider the previous case
  for(; pos<megaBlockSize; pos++){
    if( megaBlock.blocks[pos].k < k ){
      k = megaBlock.blocks[pos].k;
      blockID = pos;
    }
  }
  
  if( k == memoryBlockSize ) // The whole memory is in memristive mode!
    blockID = (megaBlock.nextAvailableBlock++)&(megaBlockSize-1UL); // use round robin to choose
  else
    megaBlock.nextAvailableBlock++;
  
  return blockID;
}

- (void) increaseAccessCounterOn:(unsigned long int*)address
{
  *address = *address * 2 + 1;
}

- (void) decreaseAccessCounterOn:(unsigned long int*)address
{
  //*address = *address / 2;
  *address = 0; // agressive 1-bit detection
}

- (void) updatePageToggleOnPage:(struct Page*)aPage
{
  aPage->timeStamp = GlobalTime; // update timeStamp
  [self increaseAccessCounterOn:&(aPage->recentAccessCount)];
  
  if( aPage->memristiveMode )
    for( int i=0; i<blockSize; i++ )
      aPage->toggleCounters[i] += loadFromMemristorPenalty;
  else
    for( int i=0; i<blockSize; i++ )
      aPage->toggleCounters[i] += loadFromCRSPenalty;
  
  if(hybridEnabled)
    aPage->memristiveMode = YES; // Mark page as in "Memristive Mode"
}

- (void) updateToggleOnPage:(struct Page*)aPage
                 withOffset:(unsigned long int)offset
                     ofSize:(unsigned long int)size
                 withAmount:(unsigned long int)amount

{
  assert( (offset+size) <= blockSize ); // Accesses must be aligned!
  aPage->timeStamp = GlobalTime; // update timeStamp
  [self increaseAccessCounterOn:&(aPage->recentAccessCount)];
  
  if( hybridEnabled && !(aPage->memristiveMode) ) // if page is in CRS and hybrid is enabled
    [self updatePageToggleOnPage:aPage]; // Activate page
  
  for( unsigned long int i=0; i<size; i++ )
    aPage->toggleCounters[i+offset] += amount;
}

- (void) releaseMemory
{
  printf("%s evictionCount = %lu\n", [name UTF8String], evictionCount);
  
  if( tCountByPage != NULL )
    free(tCountByPage);
  if( kMap != NULL )
    free(kMap);
  if( aMap != NULL )
    free(aMap);
  [pageTable releaseMemory];
  for( unsigned long int i = 0; i<megaBlockSize; i++ ){
    for( unsigned long int j = 0; j<memoryBlockSize; j++ ){
      free(megaBlock.blocks[i].pages[j].toggleCounters);
    }
    free(megaBlock.blocks[i].pages);
  }
  free(megaBlock.blocks);
}

- (void) printCapacity
{
  int c = 0;
  unsigned long int n = capacityInBytes;
  while(n){
    n = n >> 1;
    c++;
  }
  c--;
  int unit_n = c/10;
  char unit[3] = "B";
  switch (unit_n) {
    case 0:
      strcpy(unit, "B");
      break;
    case 1:
      strcpy(unit, "KB");
      break;
    case 2:
      strcpy(unit, "MB");
      break;
    case 3:
      strcpy(unit, "GB");
      break;
    case 4:
      strcpy(unit, "TB");
      break;
    case 5:
      strcpy(unit, "PB");
      break;
    case 6:
      strcpy(unit, "EB");
      break;
    default:
      break;
  }
  
  int number = 1 << (c%10);
  sprintf(memoryCapacity, "%d%s", number, unit);
  printf(" -** %s memory capacity: %s  **-\n", [name UTF8String], memoryCapacity);
}

- (unsigned long int*) computeToggleByPage
{
  if( tCountByPage == NULL )
    tCountByPage = (unsigned long int*) malloc( sizeof(unsigned long int) * pages );
  assert( tCountByPage != NULL );
  unsigned long int pageIndex = 0;
  for( int i=0; i<megaBlockSize; i++ ){
    for( int j=0; j<memoryBlockSize; j++ ){
      unsigned long int tPageCount = 0;
      for( int k=0; k<pageSize; k++ ){
        tPageCount += megaBlock.blocks[i].pages[j].toggleCounters[k];
      }
      tCountByPage[pageIndex++] = tPageCount;
    }
  }
  assert( pageIndex == pages );
  
  return tCountByPage;
}

- (unsigned long int*) computeToggleByByte
{
  if( tCountByByte == NULL )
    tCountByByte = (unsigned long int*) malloc( sizeof(unsigned long int) * bytes );
  assert( tCountByByte != NULL );
  unsigned long int byteIndex = 0;
  for( int i=0; i<megaBlockSize; i++ ){
    for( int j=0; j<memoryBlockSize; j++ ){
      for( int k=0; k<pageSize; k++ ){
        tCountByByte[byteIndex++] = megaBlock.blocks[i].pages[j].toggleCounters[k];
      }
    }
  }
  assert( byteIndex == bytes );
  
  return tCountByByte;
}

- (unsigned long int*) kMap
{
  if( kMap == NULL )
    kMap = (unsigned long int*) malloc( sizeof(unsigned long int)*megaBlockSize );
  
  for(unsigned long int i = 0; i<megaBlockSize; i++)
    kMap[i] = megaBlock.blocks[i].k;
  
  return kMap;
}

- (unsigned long int*) aMap
{
  if( aMap == NULL )
    aMap = (unsigned long int*) malloc( sizeof(unsigned long int)*megaBlockSize );
  
  for(unsigned long int i = 0; i<megaBlockSize; i++)
    aMap[i] = megaBlock.blocks[i].a;
  
  return aMap;
}

- (NSString*) memoryCapacity
{
  return [NSString stringWithFormat:@"%s", memoryCapacity];
}

- (double) memristiveFraction
{
  unsigned long int availablePositions = pages;
  unsigned long int occupiedPositions = 0;
  for( int i=0; i<megaBlockSize; i++ )
    for( int j=0; j<memoryBlockSize; j++ )
      if( megaBlock.blocks[i].pages[j].memristiveMode )
        occupiedPositions++;
  
  unsigned long int aux = 0;
  for( int i=0; i<megaBlockSize; i++ )
    aux += megaBlock.blocks[i].k;
  
  assert(occupiedPositions == aux); // Check integrity of kMaps
  
  return (double) occupiedPositions/availablePositions;
}

- (void) deactivateUnsedBlocks
{
  assert(hybridEnabled);
  for( int i=0; i<megaBlockSize; i++ ){
    for( int j=0; j<memoryBlockSize; j++ ){
      if( (megaBlock.blocks[i].pages[j].memristiveMode) && (megaBlock.blocks[i].pages[j].recentAccessCount == 0) ){
        megaBlock.blocks[i].pages[j].memristiveMode = NO; // put page in CRS mode
        megaBlock.blocks[i].k--;
        megaBlock.blocks[i].d += blockSize; // the whole page is deactivated
        for( int k=0; k<blockSize; k++ )
          megaBlock.blocks[i].pages[j].toggleCounters[k] += deactivationPenalty; // update toggle count accordingly
      }
      [self decreaseAccessCounterOn:&(megaBlock.blocks[i].pages[j].recentAccessCount)];
    }
  }
}

- (struct EnergyBundle) getEnergyConsumption
{
  struct EnergyBundle energyBundle = {0.0, 0.0, 0.0};
  if(accessCount_diff == 0)
    return energyBundle; // if memory is not used in this time lapse, no energy was spent
 
  double readEnergy = 0.0;
  double writeEnergy = 0.0;
  double deactivationEnergy = 0.0;
  
  unsigned long int reads = 0;
  unsigned long int writes = 0;
  
  for(unsigned long int i=0; i<megaBlockSize; i++){
    double memristiveBlockFraction = (double)megaBlock.blocks[i].k/memoryBlockSize;
    double memristiveHitRate = (double)mHits_diff/accessCount_diff;
    unsigned long int r = megaBlock.blocks[i].r;
    unsigned long int w = megaBlock.blocks[i].w;
    unsigned long int d = megaBlock.blocks[i].d;
    
    reads += r;
    writes += w;
    
    if( crsOnlyEnabled ){
      readEnergy += [GlobalFunctions C_readEnergyWithP:_p r:_r np:(memoryBlockSize-1) e:_e S:_S R:_R] * r;
      writeEnergy += [GlobalFunctions C_writeEnergyWithP:_p r:_r np:(memoryBlockSize-1) e:_e CC:_CC] * w;
    } else if (hybridEnabled){
      readEnergy += [GlobalFunctions H_readEnergyWithP:_p r:_r np:(memoryBlockSize-1) e:_e S:_S CC:_CC m:memristiveBlockFraction h:memristiveHitRate] * r;
      writeEnergy += [GlobalFunctions h_writeEnergyWithP:_p r:_r np:(memoryBlockSize-1) e:_e S:_S R:_R CC:_CC m:memristiveBlockFraction h:memristiveHitRate] * w;
      deactivationEnergy += [GlobalFunctions deactivationEnergyWithP:_p r:_r np:(memoryBlockSize-1) e:_e R:_R CC:_CC m:memristiveBlockFraction] * d;
    } else{
      readEnergy += [GlobalFunctions M_readEnergyWithP:_p r:_r np:(memoryBlockSize-1) e:_e] * r;
      writeEnergy += [GlobalFunctions M_writeEnergyWithP:_p r:_r np:(memoryBlockSize-1) e:_e S:_S R:_R] * w;
    }
  }
  
  //printf("\n%s:\n  RE:%f\n  WE:%f\n  RC:%lu\n  WC:%lu\n", [name UTF8String], readEnergy, writeEnergy, reads, writes);
  
  // Reset differential counters
  [self resetAccessCounters];
  mHits_diff = 0;
  mMisses_diff = 0;
  accessCount_diff = 0;
  
  energyBundle.readEnergy = readEnergy;
  energyBundle.writeEnergy = writeEnergy;
  energyBundle.deactivationEnergy = deactivationEnergy;

  return energyBundle;
}

- (void) resetAccessCounters
{
  for(unsigned long int i=0; i<megaBlockSize; i++){
    megaBlock.blocks[i].a = 0; // access
    megaBlock.blocks[i].r = 0; // read
    megaBlock.blocks[i].w = 0; // write
    megaBlock.blocks[i].d = 0; // deactivation
  }
}

@end
