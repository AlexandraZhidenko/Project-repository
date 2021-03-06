//
//  OutputTextView.m
//  ListOfClosedTasks
//
//  Created by Александра Жиденко on 28.08.18.
//  Copyright © 2018 Александра Жиденко. All rights reserved.
//

#import "OutputTextView.h"

@implementation OutputTextView

NSString *kPrivateDragUTI = @"com.CCoding.DragNDrop";

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    self.backgroundColor = [NSColor whiteColor];
    
    if (self.highlight) // highlight window
    {
        [[NSColor lightGrayColor] set];
        [NSBezierPath setDefaultLineWidth:5];
        [NSBezierPath strokeRect:dirtyRect];
    }
}

-(id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    return self;
}

-(NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender
{
    [[NSApp mainWindow] setCollectionBehavior:NSWindowCollectionBehaviorStationary|NSWindowCollectionBehaviorCanJoinAllSpaces|NSWindowCollectionBehaviorFullScreenAuxiliary];
    if ([sender draggingSourceOperationMask] & NSDragOperationCopy)
    {
        self.string = @"";
        self.highlight = YES;
        
        return NSDragOperationCopy;
    }
    return NSDragOperationNone;
}

- (void)draggingExited:(id<NSDraggingInfo>)sender
{
    self.highlight = NO;
}

- (BOOL)prepareForDragOperation:(id<NSDraggingInfo>)sender
{
    self.fileTypesTextView = [NSArray arrayWithObjects:@"xml",nil];
    self.highlight = NO;
    
    for(int i = 0; i < self.fileTypesTextView.count; i++)
    {
        if([[[[NSURL URLFromPasteboard:[sender draggingPasteboard]] path] stringByResolvingSymlinksInPath] hasSuffix:self.fileTypesTextView[i]])
        {
            return YES;
        }
    }
    return NO;
}

- (BOOL)performDragOperation:(id<NSDraggingInfo>)sender
{
    ViewController* vc = [[ViewController alloc] init];
    vc.outputTextView = [[OutputTextView alloc] init];
    
    vc.arrayClosedTasks = [[NSMutableArray alloc] initWithCapacity:0];
    vc.arrayClosedTasks_Bank = [NSMutableArray arrayWithCapacity:0];
    vc.arrayClosedTasks_Test = [NSMutableArray arrayWithCapacity:0];
    
    vc.fileTypes = [NSArray arrayWithObjects:@"xml",nil];
    
    vc.outputTextView.delegate = self;
    
    if ([sender draggingSource] != self)
    {
        NSURL *fileURL = [NSURL URLFromPasteboard:[sender draggingPasteboard]];
        NSString* path = [[fileURL path] stringByResolvingSymlinksInPath];
        
        NSString* str = [[NSString alloc] initWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
        NSError *error = nil;
        self.xml = [XMLReader dictionaryForXMLString:str error:&error];
        
        vc.arrayClosedTasks = [[NSMutableArray alloc] initWithCapacity:0];
        vc.arrayClosedTasks_Bank = [NSMutableArray arrayWithCapacity:0];
        vc.arrayClosedTasks_Test = [NSMutableArray arrayWithCapacity:0];
        
        vc.arrayTasks = [vc getArrayDicts:self.xml];
        vc.tasks = [NSMutableArray arrayWithCapacity:0];
        for(int i = 0; i < vc.arrayTasks.count; i++)
        {
            Task *task = [[Task alloc] initWithDictionary:vc.arrayTasks[i]];
            
            task.block = ^{
                [vc reloadView:self];
            };
            [vc.tasks addObject:task];
        }
        [vc reloadView:self];
    }
    return YES;
}

@end
