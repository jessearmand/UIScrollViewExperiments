//
//  UISVRLEPhotoTableViewCell.m
//
//  Created by Jesse Armand on 1/3/12.
//

#import "UISVRLEPhotoTableViewCell.h"

@implementation UISVRLEPhotoTableViewCell

@synthesize photoImageView;
@synthesize photoTitleLabel;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
  if (self) {
  }
  return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
  [super setSelected:selected animated:animated];
}

@end
