//
//  ViewController.m
//  SKTest
//
//  Created by Leo Natan (Wix) on 12/27/18.
//  Copyright © 2018 Leo Natan. All rights reserved.
//

#import "ViewController.h"
#import "GameScene.h"

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Load the SKScene from 'GameScene.sks'
    GameScene *scene = (GameScene *)[SKScene nodeWithFileNamed:@"GameScene"];
    
    // Set the scale mode to scale to fit the window
    scene.scaleMode = SKSceneScaleModeResizeFill;
	scene.backgroundColor = NSColor.clearColor;
    
    // Present the scene
    [self.skView presentScene:scene];
	self.skView.allowsTransparency = YES;
	
	// Load the SKScene from 'GameScene.sks'
	GameScene *scene2 = (GameScene *)[SKScene nodeWithFileNamed:@"GameScene"];
	
	// Set the scale mode to scale to fit the window
	scene2.scaleMode = SKSceneScaleModeResizeFill;
	scene2.backgroundColor = NSColor.clearColor;
	
	// Present the scene
	[self.skView2 presentScene:scene2];
	self.skView2.allowsTransparency = YES;
	
	// Load the SKScene from 'GameScene.sks'
	GameScene *scene3 = (GameScene *)[SKScene nodeWithFileNamed:@"GameScene"];
	
	// Set the scale mode to scale to fit the window
	scene3.scaleMode = SKSceneScaleModeResizeFill;
	scene3.backgroundColor = NSColor.clearColor;
	
	// Present the scene
	[self.skView3 presentScene:scene3];
	self.skView3.allowsTransparency = YES;
}

@end
