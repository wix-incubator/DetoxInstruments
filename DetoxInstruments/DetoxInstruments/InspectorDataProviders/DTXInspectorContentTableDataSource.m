//
//  DTXContentAwareTableDataSource.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 14/06/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXInspectorContentTableDataSource.h"
#import "DTXTextViewCellView.h"
#import "DTXViewCellView.h"
#import "DTXStackTraceCellView.h"
#import "DTXObjectsCellView.h"
@import QuartzCore;

@interface DTXTextAttachment : NSTextAttachment @end

@implementation DTXTextAttachment

- (NSRect)attachmentBoundsForTextContainer:(nullable NSTextContainer *)textContainer proposedLineFragment:(NSRect)lineFrag glyphPosition:(CGPoint)position characterIndex:(NSUInteger)charIndex
{
	CGFloat width = MIN(lineFrag.size.width, self.image.size.width);
	CGFloat height = (self.image.size.height / self.image.size.width) * width;
	
	return NSMakeRect(0, 0, width, height);
}

@end

@implementation DTXInspectorContentRow

@synthesize description=_description;

+ (instancetype)contentRowWithTitle:(NSString *)title description:(NSString *)description
{
	return [self contentRowWithTitle:title description:description color:NSColor.labelColor];
}

+ (instancetype)contentRowWithTitle:(NSString*)title description:(NSString*)description color:(NSColor*)color
{
	DTXInspectorContentRow* rv = [DTXInspectorContentRow new];
	rv.title = title;
	rv.description = description;
	rv.color = color;
	
	return rv;
}

+ (instancetype)contentRowWithTitle:(NSString*)title attributedDescription:(NSAttributedString*)attributedDescription
{
	DTXInspectorContentRow* rv = [DTXInspectorContentRow new];
	rv.title = title;
	rv.attributedDescription = attributedDescription;
	
	return rv;
}

+ (instancetype)contentRowWithNewLine
{
	return [self contentRowWithTitle:@"\n" description:@"\n"];
}

- (BOOL)isNewLine
{
	return [self.title isEqualToString:@"\n"] && [self.description isEqualToString:@"\n"];
}

- (BOOL)isEqual:(DTXInspectorContentRow*)object
{
	__block BOOL equal = YES;
	
	equal &= (self.title == object.title || [self.title isEqualToString:object.title]);
	equal &= (self.description == object.description || [self.description isEqualToString:object.description]);

	if([self.attributedDescription containsAttachmentsInRange:NSMakeRange(0, self.attributedDescription.length)])
	{
		equal &= (self.attributedDescription.length == object.attributedDescription.length);
		
		NSMutableArray<NSTextAttachment*>* selfAttachments = [NSMutableArray new];
		[self.attributedDescription enumerateAttribute:NSAttachmentAttributeName inRange:NSMakeRange(0, self.attributedDescription.length) options:0 usingBlock:^(id  _Nullable value, NSRange range, BOOL * _Nonnull stop) {
			if(value)
			{
				[selfAttachments addObject:value];
			}
		}];
		
		NSMutableArray<NSTextAttachment*>* objectAttachments = [NSMutableArray new];
		[object.attributedDescription enumerateAttribute:NSAttachmentAttributeName inRange:NSMakeRange(0, object.attributedDescription.length) options:0 usingBlock:^(id  _Nullable value, NSRange range, BOOL * _Nonnull stop) {
			if(value)
			{
				[objectAttachments addObject:value];
			}
		}];
		
		equal &= (selfAttachments.count == objectAttachments.count);
		if(equal)
		{
			[selfAttachments enumerateObjectsUsingBlock:^(NSTextAttachment * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
				if(obj.image)
				{
					equal &= [obj.image.TIFFRepresentation isEqualToData:objectAttachments[idx].image.TIFFRepresentation];
				}
				else
				{
					NSFileWrapper* objWrapper = obj.fileWrapper;
					NSFileWrapper* otherWrapper = objectAttachments[idx].fileWrapper;
					equal &= (objWrapper == otherWrapper || [objWrapper.regularFileContents isEqualToData:otherWrapper.regularFileContents]);
				}
			}];
		}
	}
	else
	{
		equal &= (self.attributedDescription == object.attributedDescription || [self.attributedDescription isEqualToAttributedString:object.attributedDescription]);
	}
	equal &= (self.color == object.color || [self.color isEqual:object.color]);
	
	return equal;
}

@end

@implementation DTXInspectorContent

- (BOOL)isEqual:(DTXInspectorContent*)object
{
	BOOL equal = YES;
	
	equal &= (self.title == object.title || [self.title isEqualToString:object.title]);
	equal &= (self.isGroup == object.isGroup);
	equal &= (self.content == object.content ||  [self.content isEqualToArray:object.content]);
	equal &= (self.setupForWindowWideCopy == object.setupForWindowWideCopy);
	equal &= (self.image == object.image || [self.image.TIFFRepresentation isEqualToData:object.image.TIFFRepresentation]);
	equal &= (self.customView == object.customView || [self.customView isEqual:object.customView]);
	equal &= (self.stackFrames == object.stackFrames || [self.stackFrames isEqualToArray:object.stackFrames]);
	equal &= (self.objects == object.objects || [self.objects isEqualToArray:object.objects]);
	
	return equal;
}

@end

@interface DTXInspectorContentTableDataSource () <NSTableViewDataSource, NSTableViewDelegate>
{
	NSMutableArray<NSMutableAttributedString*>* _attributedStrings;
}

@end

@implementation DTXInspectorContentTableDataSource

- (void)setManagedTableView:(NSTableView *)managedTableView
{
	//Cleanup
	_managedTableView.dataSource = nil;
	_managedTableView.delegate = nil;
	[_managedTableView reloadData];
	
	_managedTableView = managedTableView;
	[self _prepareAttributedStrings];
	
	_managedTableView.usesAutomaticRowHeights = YES;
	
	_managedTableView.dataSource = self;
	_managedTableView.delegate = self;
}

- (void)setContentArray:(NSArray<DTXInspectorContent *> *)contentArray animateTransition:(BOOL)animate
{
	if([_contentArray isEqualToArray:contentArray])
	{
		return;
	}
	
	[_managedTableView layoutSubtreeIfNeeded];
	
	if(animate == NO)
	{
		_contentArray = [contentArray copy];
		[self _prepareAttributedStrings];
		[_managedTableView reloadData];
		
		return;
	}
	
	[NSAnimationContext beginGrouping];
	NSAnimationContext.currentContext.duration = 0.3;
	NSAnimationContext.currentContext.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
	
	[_managedTableView beginUpdates];
	
	[_managedTableView removeRowsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [self numberOfRowsInTableView:_managedTableView])] withAnimation:NSTableViewAnimationEffectFade];
	
	_contentArray = @[];
	[self _prepareAttributedStrings];
	
	[_managedTableView endUpdates];
	[NSAnimationContext endGrouping];
	
	//Without this, NSTableView bugged out and produced broken cell layout from time to time.
	dispatch_async(dispatch_get_main_queue(), ^{
		[NSAnimationContext beginGrouping];
		NSAnimationContext.currentContext.duration = 0.3;
		NSAnimationContext.currentContext.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
		
		[_managedTableView beginUpdates];
		
		_contentArray = [contentArray copy];
		[self _prepareAttributedStrings];
		
		[_managedTableView insertRowsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [self numberOfRowsInTableView:_managedTableView])] withAnimation:NSTableViewAnimationEffectFade | NSTableViewAnimationSlideUp];
		
		[_managedTableView endUpdates];
		[NSAnimationContext endGrouping];
	});
}

- (void)setContentArray:(NSArray<DTXInspectorContent *> *)contentArray
{
	[self setContentArray:contentArray animateTransition:NO];
}

- (void)_prepareAttributedStrings
{
	if(_managedTableView == nil)
	{
		return;
	}
	
	_attributedStrings = [NSMutableArray new];
	
	NSTextField* textField = [[_managedTableView makeViewWithIdentifier:@"DTXTextViewCellView" owner:nil] contentTextField];
	NSFont* fontFromTableView = textField.font;
	
	[_contentArray enumerateObjectsUsingBlock:^(DTXInspectorContent * _Nonnull content, NSUInteger idx, BOOL * _Nonnull stop) {
		NSMutableAttributedString* mas = [NSMutableAttributedString new];
		if(content.image)
		{
			DTXTextAttachment* ta = [DTXTextAttachment new];
			ta.image = content.image;
			[ta.image setValue:@YES forKey:@"flipped"];
			
			[mas appendAttributedString:[NSAttributedString attributedStringWithAttachment:ta]];
		}
		else
		{
			[content.content enumerateObjectsUsingBlock:^(DTXInspectorContentRow * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
				if(obj.isNewLine)
				{
					[mas appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n" attributes:@{NSFontAttributeName: [NSFont systemFontOfSize:fontFromTableView.pointSize weight:NSFontWeightRegular]}]];
					return;
				}
				
				if(obj.description == nil && obj.attributedDescription == nil)
				{
					return;
				}
				
				if(obj.title)
				{
					[mas appendAttributedString:[[NSAttributedString alloc] initWithString:obj.title attributes:@{NSFontAttributeName: [NSFont systemFontOfSize:fontFromTableView.pointSize weight:NSFontWeightSemibold], NSForegroundColorAttributeName: textField.textColor}]];
					[mas appendAttributedString:[[NSAttributedString alloc] initWithString:@": " attributes:@{NSFontAttributeName: [NSFont systemFontOfSize:fontFromTableView.pointSize weight:NSFontWeightSemibold], NSForegroundColorAttributeName: textField.textColor}]];
				}
				
				if(obj.attributedDescription)
				{
					NSMutableAttributedString* attrDesc = obj.attributedDescription.mutableCopy;
					
					[attrDesc beginEditing];
					
					[attrDesc addAttribute:NSFontAttributeName value:[NSFont systemFontOfSize:fontFromTableView.pointSize weight:NSFontWeightRegular] range:NSMakeRange(0, attrDesc.length)];
					
					[obj.attributedDescription enumerateAttribute:NSFontAttributeName inRange:NSMakeRange(0, attrDesc.length) options:0 usingBlock:^(id  _Nullable value, NSRange range, BOOL * _Nonnull stop) {
						if(value)
						{
							[attrDesc addAttribute:NSFontAttributeName value:value range:range];
						}
					}];
					
					[attrDesc endEditing];
					
					[mas appendAttributedString:attrDesc];
				}
				else
				{
					id attrDesc = [[NSAttributedString alloc] initWithString:obj.description attributes:@{NSFontAttributeName: [NSFont systemFontOfSize:fontFromTableView.pointSize weight:NSFontWeightRegular], NSForegroundColorAttributeName: obj.color}];
					[mas appendAttributedString:attrDesc];
				}
				
				if(idx < content.content.count - 1)
				{
					[mas appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n" attributes:@{NSFontAttributeName: [NSFont systemFontOfSize:fontFromTableView.pointSize weight:NSFontWeightRegular]}]];
				}
			}];
		}
		
		NSMutableParagraphStyle* par = NSParagraphStyle.defaultParagraphStyle.mutableCopy;
		if(content.image)
		{
			par.alignment = NSTextAlignmentCenter;
		}
		else
		{
			par.lineSpacing = 2.0;
		}
		
		[mas addAttribute:NSParagraphStyleAttributeName value:par range:NSMakeRange(0, mas.length)];
		
		[_attributedStrings addObject:mas];
	}];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
	return _attributedStrings.count;
}

- (nullable NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(nullable NSTableColumn *)tableColumn row:(NSInteger)row
{
	DTXInspectorContent* content = _contentArray[row];
	
	if(content.isGroup)
	{
		NSTableCellView* groupCell = [tableView makeViewWithIdentifier:@"DTXGroupTextViewCellView" owner:nil];
		groupCell.textField.stringValue = content.title;
		groupCell.imageView.image = content.titleImage;
		return groupCell;
	}
	
	__kindof NSTableCellView* cell = [tableView makeViewWithIdentifier:content.stackFrames ? @"DTXStackTraceCellView" : content.objects ? @"DTXObjectsCellView" : content.customView ? @"DTXViewCellView" : @"DTXTextViewCellView" owner:nil];
	
	NSView* targetForWindowWideCopy = cell.imageView;
	
	if(content.stackFrames != nil)
	{
		[cell setStackFrames:content.stackFrames];
		targetForWindowWideCopy = [cell stackTraceTableView];
	}
	
	if(content.objects != nil)
	{
		[cell setObjects:content.objects];
		targetForWindowWideCopy = [cell objectsOutlineView];
	}
	
	if(content.customView == nil && content.image == nil && content.stackFrames == nil && content.objects == nil)
	{
		[cell contentTextField].attributedStringValue = _attributedStrings[row];
		[cell contentTextField].allowsEditingTextAttributes = YES;
		[cell contentTextField].selectable = YES;
		targetForWindowWideCopy = [cell contentTextField];
		
		[cell textField].hidden = content.title.length == 0;
		[cell titleContentConstraint].active = content.title.length != 0;
	}
	
	cell.textField.stringValue = content.title ?: @"Title";
	cell.imageView.image = content.titleImage;
	if([cell respondsToSelector:@selector(titleContainer)])
	{
		[cell titleContainer].fillColor = content.titleColor;
	}
	
	if(content.image)
	{
		[cell contentTextField].attributedStringValue = _attributedStrings[row];
		[cell contentTextField].selectable = NO;
		targetForWindowWideCopy = [cell contentTextField];
	}
	
	if(content.customView)
	{
		[content.customView removeFromSuperview];
		
		DTXViewCellView* viewCell = (id)cell;
		[viewCell.contentView addSubview:content.customView];
		[NSLayoutConstraint activateConstraints:@[[viewCell.contentView.topAnchor constraintEqualToAnchor:content.customView.topAnchor],
												  [viewCell.contentView.bottomAnchor constraintEqualToAnchor:content.customView.bottomAnchor],
												  [viewCell.contentView.centerXAnchor constraintEqualToAnchor:content.customView.centerXAnchor],
												  [viewCell.contentView.centerYAnchor constraintEqualToAnchor:content.customView.centerYAnchor]]];
		
		targetForWindowWideCopy = viewCell.contentView;
	}
	
	if(content.setupForWindowWideCopy)
	{
		[tableView.window.windowController setTargetForCopy:targetForWindowWideCopy];
	}
	
	return cell;
}

//- (BOOL)tableView:(NSTableView *)tableView isGroupRow:(NSInteger)row
//{
//	return _contentArray[row].isGroup;
//}

- (CGFloat)_displayHeightForString:(NSAttributedString*)string width:(CGFloat)width
{
	return [string boundingRectWithSize:NSMakeSize(width, DBL_MAX) options:NSStringDrawingUsesLineFragmentOrigin |NSStringDrawingUsesFontLeading].size.height;
}

- (int)_depthOfObjects:(id)objects
{
	int counter = 0;
	for (id obj in objects)
	{
		counter += 1;
		
		if ([obj isKindOfClass:[NSArray class]])
		{
			counter += [self _depthOfObjects:obj];
		}
		else if ([obj isKindOfClass:[NSDictionary class]])
		{
			counter += [self _depthOfObjects:[obj allObjects]];
		}
	}
	return counter;
}

@end
