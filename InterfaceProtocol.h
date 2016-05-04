//
//  InterfaceProtocol.h
//  e-HReRAM
//
//  Created by Miguel Lastras on 3/28/16.
//  Copyright © 2016 Miguel Lastras. All rights reserved.
//

#ifndef InterfaceProtocol_h
#define InterfaceProtocol_h


@protocol InterfaceProtocol
@required
- (void) accessBlock:(unsigned long int)address ofSize:(unsigned long int)size readOperation:(BOOL)read;
- (void) printCapacity;
- (void) releaseMemory;
@optional
- (NSString*) memoryCapacity;
- (unsigned long int) blockSize;
@end


#endif /* InterfaceProtocol_h */
