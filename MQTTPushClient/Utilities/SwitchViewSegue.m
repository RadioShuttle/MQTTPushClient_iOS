/*
 * This is an unpublished work copyright (c) 2015 HELIOS Software GmbH
 * 30827 Garbsen, Germany
 */

#import "SwitchViewSegue.h"

@implementation SwitchViewSegue

/*
 * Custom segue to replace the source view controller by the destination
 * view controller on the navigation stack.
 */

- (void)perform {
	UIViewController *src = (UIViewController *)self.sourceViewController;
	UIViewController *dst = (UIViewController *)self.destinationViewController;
	
	UINavigationController *nc = src.navigationController;
	NSMutableArray *viewControllers = [nc.viewControllers mutableCopy];
	viewControllers[viewControllers.count - 1] = dst;
	nc.viewControllers = viewControllers;
	
	// XXX TODO: Better animation (if possible).
#if 0
	[UIView transitionWithView:nc.view
					  duration:1.0
					   options:UIViewAnimationOptionTransitionFlipFromLeft
					animations:^{
						[nc setViewControllers:viewControllers animated:YES];
					} completion:nil];
	[UIView animateWithDuration:0.5 delay:0.0 options:UIViewAnimationOptionTransitionFlipFromLeft animations:^{
		[nc setViewControllers:viewControllers animated:YES];
	} completion:nil];
#endif
}

@end
