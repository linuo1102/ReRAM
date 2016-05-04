/*
 * MemoryHierarchy.h
 * Generic memory hierarchy
 *
 * Created by Miguel Lastras on Apr 1, 2015
 */

#import "MemoryHierarchy.h"

@implementation MemoryHierarchy

@synthesize hierarchyDescription;

- (id) init
{
  self = [super init];
  if( self != nil ){
    scenario1 = [NSMutableArray arrayWithCapacity:0];
    scenario2 = [NSMutableArray arrayWithCapacity:0];
    scenario3 = [NSMutableArray arrayWithCapacity:0];
    alignedAccesses = 0;
    unalignedAccesses = 0;
    hierarchyDescription = [NSMutableString stringWithCapacity:16];
  }
  return self;
}

- (void) addDisk:(NSString*)name
{
  [scenario1 addObject:[[Disk alloc] initWithName:[name stringByAppendingString:@" Memristive Case"]]];
  [scenario2 addObject:[[Disk alloc] initWithName:[name stringByAppendingString:@" CRS Case"]]];
  [scenario3 addObject:[[Disk alloc] initWithName:[name stringByAppendingString:@" Hybrid Case"]]];
}

- (void) addSACacheX:(NSString*)name
        withSetsBits:(unsigned long int)sb
   associativityBits:(unsigned long int)ab
   bytesPerBlockBits:(unsigned long int)bb
{  
  [scenario1 addObject:[[SACacheX alloc]
                        initWithSetsBits:sb
                        associativityBits:ab
                        bytesPerBlockBits:bb
                        nextLevel:[scenario1 lastObject]
                        name:[name stringByAppendingString:@" Memristive Case"]
                        CRSOnly:NO hybrid:NO]];
  [scenario2 addObject:[[SACacheX alloc]
                        initWithSetsBits:sb
                        associativityBits:ab
                        bytesPerBlockBits:bb
                        nextLevel:[scenario2 lastObject]
                        name:[name stringByAppendingString:@" CRS Case"]
                        CRSOnly:YES hybrid:NO]];
  [scenario3 addObject:[[SACacheX alloc]
                        initWithSetsBits:sb
                        associativityBits:ab
                        bytesPerBlockBits:bb
                        nextLevel:[scenario3 lastObject]
                        name:[name stringByAppendingString:@" Hybrid Case"]
                        CRSOnly:NO hybrid:YES]];
}

- (void)  addReRAM:(NSString*)name
      withPageSize:(unsigned long int)pz
     pagesPerBlock:(unsigned long int)ppb
blocksPerMegaBlock:(unsigned long int)bpmb
      withInitialK:(unsigned long)k
 dynamicAllocation:(BOOL)dynamicAllocation
{
  [scenario1 addObject:[[DHReRAM alloc]
                        initWithPageSize:pz
                        pagesPerBlock:ppb
                        blocksPerMegaBlock:bpmb
                        nextLevel:[scenario1 lastObject]
                        Name:[name stringByAppendingString:@" Memristive Case"]
                        CRSOnly:NO hybrid:NO initialK:k dynamicAllocation:dynamicAllocation]];
  [scenario2 addObject:[[DHReRAM alloc]
                        initWithPageSize:pz
                        pagesPerBlock:ppb
                        blocksPerMegaBlock:bpmb
                        nextLevel:[scenario2 lastObject]
                        Name:[name stringByAppendingString:@" CRS Case"]
                        CRSOnly:YES hybrid:NO initialK:k dynamicAllocation:dynamicAllocation]];
  [scenario3 addObject:[[DHReRAM alloc]
                        initWithPageSize:pz
                        pagesPerBlock:ppb
                        blocksPerMegaBlock:bpmb
                        nextLevel:[scenario3 lastObject]
                        Name:[name stringByAppendingString:@" Hybrid Case"]
                        CRSOnly:NO hybrid:YES initialK:k dynamicAllocation:dynamicAllocation]];
}

- (void) addSACache:(NSString*)name
       withSetsBits:(unsigned long int)sb
  associativityBits:(unsigned long int)ab
  bytesPerBlockBits:(unsigned long int)bb
{  
  [scenario1 addObject:[[SACache alloc]
                   initWithSetsBits:sb
                  associativityBits:ab
                  bytesPerBlockBits:bb
                          nextLevel:[scenario1 lastObject]
                               name:[name stringByAppendingString:@" Memristive Case"]]];
  [scenario2 addObject:[[SACache alloc]
                   initWithSetsBits:sb
                  associativityBits:ab
                  bytesPerBlockBits:bb
                          nextLevel:[scenario2 lastObject]
                               name:[name stringByAppendingString:@" CRS Case"]]];
  [scenario3 addObject:[[SACache alloc]
                   initWithSetsBits:sb
                  associativityBits:ab
                  bytesPerBlockBits:bb
                          nextLevel:[scenario3 lastObject]
                               name:[name stringByAppendingString:@" Hybrid Case"]]];
}

/*
- (void) addScheduler:(NSString*)name;
{
  [scenario1 addObject:[[MemoryScheduler alloc]
                        initWithNextLevel:[scenario1 lastObject]
                        name:[name stringByAppendingString:@" Memristive Case"]]];
  [scenario2 addObject:[[MemoryScheduler alloc]
                        initWithNextLevel:[scenario2 lastObject]
                        name:[name stringByAppendingString:@" CRS Case"]]];
  [scenario3 addObject:[[MemoryScheduler alloc]
                        initWithNextLevel:[scenario3 lastObject]
                        name:[name stringByAppendingString:@" Hybrid Case"]]];
}
*/
 
- (void) executeTask:(Task*)task
{
  unsigned long int firstLevelBlockSize = [[scenario1 lastObject] blockSize];
  unsigned long int blockAddress = ([task address]) & (firstLevelBlockSize-1UL);
  BOOL alignedAddress = (blockAddress + [task size]) <= firstLevelBlockSize;
  if( alignedAddress ){
    alignedAccesses++;
    [[scenario1 lastObject] accessBlock:[task address] ofSize:[task size] readOperation:[task operation]];
    [[scenario2 lastObject] accessBlock:[task address] ofSize:[task size] readOperation:[task operation]];
    [[scenario3 lastObject] accessBlock:[task address] ofSize:[task size] readOperation:[task operation]];
  }
  else{
    unalignedAccesses++;
    for( unsigned long int j=0; j<[task size]; j++ ){ // Very few accesses are expected to be unaligned...
      [[scenario1 lastObject] accessBlock:[task address]+j ofSize:1 readOperation:[task operation]];
      [[scenario2 lastObject] accessBlock:[task address]+j ofSize:1 readOperation:[task operation]];
      [[scenario3 lastObject] accessBlock:[task address]+j ofSize:1 readOperation:[task operation]];
    }
  }
}

- (void) executeTaskWithAddress:(unsigned long int)anAddress
                           size:(unsigned long int)aSize
                      operation:(BOOL)anOperation
{
  unsigned long int firstLevelBlockSize = [[scenario1 lastObject] blockSize];
  unsigned long int blockAddress = (anAddress) & (firstLevelBlockSize-1UL);
  BOOL alignedAddress = (blockAddress + aSize) <= firstLevelBlockSize;
  if( alignedAddress ){
    alignedAccesses++;
    [[scenario1 lastObject] accessBlock:anAddress ofSize:aSize readOperation:anOperation];
    [[scenario2 lastObject] accessBlock:anAddress ofSize:aSize readOperation:anOperation];
    [[scenario3 lastObject] accessBlock:anAddress ofSize:aSize readOperation:anOperation];
  }
  else{
    unalignedAccesses++;
    for( unsigned long int j=0; j<aSize; j++ ){ // Very few accesses are expected to be unaligned...
      [[scenario1 lastObject] accessBlock:anAddress+j ofSize:1 readOperation:anOperation];
      [[scenario2 lastObject] accessBlock:anAddress+j ofSize:1 readOperation:anOperation];
      [[scenario3 lastObject] accessBlock:anAddress+j ofSize:1 readOperation:anOperation];
    }
  }
}

- (void) printConfiguration
{
  NSPredicate *predicate = [NSPredicate predicateWithFormat: @"(class == %@) || (class == %@)", [SACacheX class], [DHReRAM class] ];
  NSArray *MemoryBlocks = [scenario1 filteredArrayUsingPredicate:predicate];
  for(id block in scenario1)
    [block printCapacity];
  for(id<InterfaceProtocol> block in MemoryBlocks){
    NSString *memCapacity = (NSString*)[block memoryCapacity];
    unsigned long int blockSize = (unsigned long int)[block blockSize];
    [hierarchyDescription appendFormat:@"-%@(%luB)",memCapacity, blockSize];
  }
}

- (void) writeEnduranceBlock:(SACacheX*)block toFile:(NSString*)filePath
{
  NSString *pageFilePath = [filePath stringByAppendingString:@" page.txt"];
  unsigned long int *pageEndurance = [block computeToggleByPage];
  [GlobalFunctions write:pageEndurance ofSize:[block pages] toFile:pageFilePath binary:NO];
  
  //NSString *byteFilePath = [filePath stringByAppendingString:@" byte.txt"];
  //unsigned long int *byteEndurance = [block computeToggleByByte];
  //[GlobalFunctions write:byteEndurance ofSize:[block bytes] toFile:byteFilePath binary:NO];
}

- (void) writeToggleMapsToFile:(NSString*)filePath
{
  // Extract HReRAM blocks from the memory hierarchy:
  NSPredicate *predicate = [NSPredicate predicateWithFormat: @"(class == %@) || (class == %@)", [SACacheX class], [DHReRAM class]];
  NSArray *MemristiveBlocks = [scenario1 filteredArrayUsingPredicate:predicate];
  NSArray *CRSBlocks = [scenario2 filteredArrayUsingPredicate:predicate];
  NSArray *HReRAMBlocks = [scenario3 filteredArrayUsingPredicate:predicate];

  // Write all HReRAM to file:
  for(id block in MemristiveBlocks)
    [self writeEnduranceBlock:block toFile:[filePath stringByAppendingFormat:@" %@", [block name]]];
  for(id block in CRSBlocks)
    [self writeEnduranceBlock:block toFile:[filePath stringByAppendingFormat:@" %@", [block name]]];
  for(id block in HReRAMBlocks)
    [self writeEnduranceBlock:block toFile:[filePath stringByAppendingFormat:@" %@", [block name]]];

}

- (void) writeSchedulerMapsToFile:(NSString*)filePath
{
  // Extract HReRAM blocks from the memory hierarchy:
  NSPredicate *predicate = [NSPredicate predicateWithFormat: @"class == %@", [DHReRAM class]];
  NSArray *MemristiveBlocks = [scenario1 filteredArrayUsingPredicate:predicate];
  NSArray *CRSBlocks = [scenario2 filteredArrayUsingPredicate:predicate];
  NSArray *HReRAMBlocks = [scenario3 filteredArrayUsingPredicate:predicate];
  
  for(id block in MemristiveBlocks)
    [GlobalFunctions write:[block kMap] ofSize:[block megaBlockSize] toFile:[filePath stringByAppendingFormat:@" %@.txt", [block name]] binary:NO];
  for(id block in CRSBlocks)
    [GlobalFunctions write:[block kMap] ofSize:[block megaBlockSize] toFile:[filePath stringByAppendingFormat:@" %@.txt", [block name]] binary:NO];
  for(id block in HReRAMBlocks)
    [GlobalFunctions write:[block kMap] ofSize:[block megaBlockSize] toFile:[filePath stringByAppendingFormat:@" %@.txt", [block name]] binary:NO];
}

- (void) resetCounters
{
  NSPredicate *predicate = [NSPredicate predicateWithFormat: @"class == %@", [SACacheX class]];
  NSArray *MemristiveBlocks = [scenario1 filteredArrayUsingPredicate:predicate];
  NSArray *CRSBlocks = [scenario2 filteredArrayUsingPredicate:predicate];
  NSArray *HReRAMBlocks = [scenario3 filteredArrayUsingPredicate:predicate];

  // Write all HReRAM to file:
  for(id block in MemristiveBlocks) [block resetEndurance];
  for(id block in CRSBlocks) [block resetEndurance];
  for(id block in HReRAMBlocks) [block resetEndurance];
}

- (void) releaseMemory
{
  for(id block in scenario1) [block releaseMemory];
  for(id block in scenario2) [block releaseMemory];
  for(id block in scenario3) [block releaseMemory];
}

- (void) deactivateUnsedBlocks
{
  NSPredicate *predicate = [NSPredicate predicateWithFormat: @"class == %@", [DHReRAM class]];
  NSArray *HReRAMBlocks = [scenario3 filteredArrayUsingPredicate:predicate];
  for(id block in HReRAMBlocks){
    [block deactivateUnsedBlocks];
  }
}

- (void) printValues
{
  NSPredicate *predicate = [NSPredicate predicateWithFormat: @"(class == %@) || (class == %@)", [SACacheX class], [DHReRAM class]];
  NSArray *HReRAMBlocks = [scenario3 filteredArrayUsingPredicate:predicate]; // to print global counters
  
  DHReRAM *memristive = [[scenario1 filteredArrayUsingPredicate:predicate] objectAtIndex:0];
  DHReRAM *crs = [[scenario2 filteredArrayUsingPredicate:predicate] objectAtIndex:0];
  DHReRAM *hybrid = [[scenario3 filteredArrayUsingPredicate:predicate] objectAtIndex:0];
  
  struct EnergyBundle crs_energy = [crs getEnergyConsumption];
  struct EnergyBundle hybrid_energy = [hybrid getEnergyConsumption];
  struct EnergyBundle memristive_energy = [memristive getEnergyConsumption];
  
  fprintf(savingsFile, "%lu, %f, %f, %f, %f, %f, %f, %f, %f, %f\n",GlobalTime, crs_energy.readEnergy, crs_energy.writeEnergy, crs_energy.deactivationEnergy, hybrid_energy.readEnergy, hybrid_energy.writeEnergy, hybrid_energy.deactivationEnergy, memristive_energy.readEnergy, memristive_energy.writeEnergy, memristive_energy.deactivationEnergy);
  
  fprintf(hitMissCounters, "%lu, ", GlobalTime);
  fprintf(memristiveFraction, "%lu, ", GlobalTime);
  fprintf(memristiveHitMissCounters, "%lu, ", GlobalTime);
  
  // Write all HReRAM to file:
  for(id block in HReRAMBlocks){
    fprintf(hitMissCounters, "%lu, %lu, %lu, ", [block accessCount], [block hits], [block misses]);
    fprintf(memristiveFraction, "%f, ", [block memristiveFraction]);
    fprintf(memristiveHitMissCounters, "%lu, %lu, %lu, ", [block accessCount], [block mHits], [block mMisses]);
  }
  fprintf(hitMissCounters,"\n");
  fprintf(memristiveFraction, "\n");
  fprintf(memristiveHitMissCounters, "\n");
}

@end
