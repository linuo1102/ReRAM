/*
 * MemoryHierarchy.h 
 * Generic memory hierarchy
 * 
 * Created by Miguel Lastras on Apr 1, 2015
 */

#import <Foundation/Foundation.h>
#import "Disk.h"
#import "SACacheX.h"
#import "SACache.h"
#import "DHReRAM.h"
#import "Task.h"
#import "GlobalFunctions.h"

@interface MemoryHierarchy : NSObject {
  NSMutableArray *scenario1;
  NSMutableArray *scenario2;
  NSMutableArray *scenario3;
  unsigned long int alignedAccesses;
  unsigned long int unalignedAccesses;
  NSMutableString *hierarchyDescription;
}

@property (nonatomic, readonly) NSMutableString *hierarchyDescription;

// Public interface
- (void) addDisk:(NSString*)name;
- (void)  addReRAM:(NSString*)name
      withPageSize:(unsigned long int)pz
     pagesPerBlock:(unsigned long int)ppb
blocksPerMegaBlock:(unsigned long int)bpmb
      withInitialK:(unsigned long int)k
 dynamicAllocation:(BOOL)dynamicAllocation;
- (void) addSACacheX:(NSString*)name
     withSetsBits:(unsigned long int)sb
associativityBits:(unsigned long int)ab
bytesPerBlockBits:(unsigned long int)bb;
- (void) addSACache:(NSString*)name
       withSetsBits:(unsigned long int)sb 
  associativityBits:(unsigned long int)ab 
  bytesPerBlockBits:(unsigned long int)bb;
//- (void) addScheduler:(NSString*)name;

- (void) executeTask:(Task*)task;
- (void) executeTaskWithAddress:(unsigned long int)anAddress
                           size:(unsigned long int)aSize
                      operation:(BOOL)anOperation;
- (void) printConfiguration;
- (void) writeEnduranceBlock:(SACacheX *)block toFile:(NSString*)filePath;
- (void) writeToggleMapsToFile:(NSString*)filePath;
- (void) writeSchedulerMapsToFile:(NSString*)filePath;
- (void) resetCounters;
- (void) releaseMemory;
- (void) printValues;
- (void) deactivateUnsedBlocks;
@end

