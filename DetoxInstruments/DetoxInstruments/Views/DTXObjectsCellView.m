//
//  DTXObjectsCellView.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 24/08/2017.
//  Copyright © 2017-2021 Wix. All rights reserved.
//

#import "DTXObjectsCellView.h"
#import "DTXStackTraceCellView.h"

@interface DTXObjectsCellView () <NSOutlineViewDataSource, NSOutlineViewDelegate>
{
	NSMapTable<id, NSAttributedString*>* _objectsTitlesMap;
	NSMapTable<id, id>* _hashToObjectsMap;
	
}

@property (nonatomic, weak, readwrite) IBOutlet NSOutlineView* objectsOutlineView;

@end

static id __keyForObject(id obj)
{
	return [NSValue valueWithNonretainedObject:obj];
//	return [NSString stringWithFormat:@"%p", obj];
}


@implementation DTXObjectsCellView

+ (NSFont*)fontForObjectDisplay
{
	static NSFont* font;
	
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		font = [NSFont fontWithName:@"SFMono-Regular" size:12];
		
		if(font == nil)
		{
			//There is no SFMono in the system, use Menlo instead.
			font = [NSFont fontWithName:@"Menlo" size:12];
		}
	});
	
	return font;
}

- (void)awakeFromNib
{
	[super awakeFromNib];
	
	_objectsOutlineView.intercellSpacing = NSZeroSize;
	_objectsOutlineView.dataSource = self;
	_objectsOutlineView.delegate = self;
	_objectsOutlineView.usesAutomaticRowHeights = NO;
	
	[_objectsOutlineView reloadData];
}

- (BOOL)_isExpandable:(id)obj
{
	return [obj isKindOfClass:[NSDictionary class]] || [obj isKindOfClass:[NSArray class]];
}

- (void)_traverseObject:(id)obj withTitle:(NSString*)title
{
	[_hashToObjectsMap setObject:obj forKey:__keyForObject(obj)];
	
	NSString* actualTitle = title ?: [obj isKindOfClass:[NSDictionary class]] ? NSLocalizedString(@"Object", @"") : [obj isKindOfClass:[NSArray class]] ? NSLocalizedString(@"Array", @"") : [obj description] ?: @"(?)";
	
	static NSColor* numberColor;
	static NSColor* keyColor;
	static NSColor* stringColor;
	static NSColor* typeColor;
	
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		numberColor = [NSColor labelColor];
		keyColor = [NSColor labelColor];
		stringColor = [NSColor labelColor];
		typeColor = [NSColor labelColor];
	});
	
	NSMutableAttributedString* attrTitle = [NSMutableAttributedString new];
	if([obj isKindOfClass:[NSArray class]])
	{
		[attrTitle appendAttributedString:[[NSAttributedString alloc] initWithString:actualTitle attributes:@{NSForegroundColorAttributeName: keyColor}]];
		[attrTitle appendAttributedString:[[NSAttributedString alloc] initWithString:@": "]];
		[attrTitle appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ (%@)", NSLocalizedString(@"Array", @""), @([obj count])] attributes:@{NSForegroundColorAttributeName: typeColor}]];
		
		[obj enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
			[self _traverseObject:obj withTitle:[NSString stringWithFormat:@"%@", @(idx)]];
		}];
	}
	else if([obj isKindOfClass:[NSDictionary class]])
	{
		[attrTitle appendAttributedString:[[NSAttributedString alloc] initWithString:actualTitle attributes:@{NSForegroundColorAttributeName: keyColor}]];
		[attrTitle appendAttributedString:[[NSAttributedString alloc] initWithString:@": "]];
		[attrTitle appendAttributedString:[[NSAttributedString alloc] initWithString:NSLocalizedString(@"Object", @"") attributes:@{NSForegroundColorAttributeName: typeColor}]];
		
		NSArray* sortedKeys = [[obj allKeys] sortedArrayUsingSelector:@selector(compare:)];
		[sortedKeys enumerateObjectsUsingBlock:^(id  _Nonnull key, NSUInteger idx, BOOL * _Nonnull stop) {
			id val = [obj objectForKey:key];
			
			[self _traverseObject:val withTitle:[NSString stringWithFormat:@"%@", key]];
		}];
	}
	else
	{
		[attrTitle appendAttributedString:[[NSAttributedString alloc] initWithString:actualTitle attributes:@{NSForegroundColorAttributeName: keyColor}]];
		[attrTitle appendAttributedString:[[NSAttributedString alloc] initWithString:@": "]];
		[attrTitle appendAttributedString:[[NSAttributedString alloc] initWithString:[obj description] attributes:@{NSForegroundColorAttributeName: [obj isKindOfClass:[NSString class]] ? stringColor : numberColor}]];
	}
	
	[attrTitle addAttribute:NSFontAttributeName value:[self.class fontForObjectDisplay] range:NSMakeRange(0, attrTitle.length)];
	
	[_objectsTitlesMap setObject:attrTitle forKey:__keyForObject(obj)];
}

- (void)setObjects:(NSArray *)objects
{
	_objectsTitlesMap = [NSMapTable new];
	_hashToObjectsMap = [NSMapTable new];
	
	_objects = objects;
	
	[_objects enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		[self _traverseObject:obj withTitle:nil];
	}];
	
	[_objectsOutlineView reloadData];
	[_objectsOutlineView.enclosingScrollView invalidateIntrinsicContentSize];
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(nullable id)item
{
	if(item == nil)
	{
		return self.objects.count;
	}
	
	item = [_hashToObjectsMap objectForKey:item];
	
	if([item isKindOfClass:[NSArray class]] || [item isKindOfClass:[NSDictionary class]])
	{
		return [(NSArray*)item count];
	}
	
	return 0;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(nullable id)item
{
	if(item == nil)
	{
		return __keyForObject(self.objects[index]);
	}
	
	item = [_hashToObjectsMap objectForKey:item];
	
	if([item isKindOfClass:[NSArray class]])
	{
		return __keyForObject([(NSArray*)item objectAtIndex:index]);
	}
	
	if([item isKindOfClass:[NSDictionary class]])
	{
		NSDictionary* dict = item;
		NSArray* sortedKeys = [dict.allKeys sortedArrayUsingSelector:@selector(compare:)];
		
		return __keyForObject(dict[sortedKeys[index]]);
	}
	
	return nil;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
	item = [_hashToObjectsMap objectForKey:item];
	
	if([item isKindOfClass:[NSArray class]] || [item isKindOfClass:[NSDictionary class]])
	{
		return YES;
	}
	
	return NO;
}

- (nullable NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(nullable NSTableColumn *)tableColumn item:(id)item
{
	item = [_hashToObjectsMap objectForKey:item];
	
	NSTableCellView* cellView = [outlineView makeViewWithIdentifier:@"ObjectCell" owner:nil];
	
	NSAttributedString* str = [_objectsTitlesMap objectForKey:__keyForObject(item)];
	
	cellView.textField.attributedStringValue = str;
	cellView.textField.allowsDefaultTighteningForTruncation = NO;
	cellView.toolTip = str.string;
	
	return cellView;
}

- (CGFloat)outlineView:(NSOutlineView *)outlineView heightOfRowByItem:(id)item
{
//	item = [_hashToObjectsMap objectForKey:item];
	
	return DTXStackTraceCellView.heightForStackFrame;
}

- (void)outlineViewItemDidExpand:(NSNotification *)notification
{
	[_objectsOutlineView.enclosingScrollView invalidateIntrinsicContentSize];
}

- (void)outlineViewItemDidCollapse:(NSNotification *)notification
{
	[_objectsOutlineView.enclosingScrollView invalidateIntrinsicContentSize];
}

@end
