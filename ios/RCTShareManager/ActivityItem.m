-(id)activityViewControllerPlaceholderItem:(UIActivityViewController *)activityViewController
{
    return _image;
}

-(id)activityViewController:(UIActivityViewController *)activityViewController itemForActivityType:(NSString *)activityType
{
    return _imagePath;
}