# StatusView
An NSView subclass to display status icons with Core Animation, written in Swift

SpinningProgressIndicator is based on [YRKSpinningProgressIndicatorLayer](https://github.com/kelan/YRKSpinningProgressIndicatorLayer) by Kelan Champagne

<br>
Usage
-----

- Add StatusView.swift and SpinningProgressIndicatorLayer.swift to your project
- Set the class of the view to StatusView
- The view is supposed to be square (aspect ratio of 1:1)

<br>
Properties
----------

- **status** : *.None, .Processing, .Failed, .Caution* and *.Success*
- **enabled** : Bool *true* or *false* - is the view enabled
- **inverted** : Bool *true* or *false* - display the symbols (except the spinning indicator) normal or inverted

The properties Inverted and Enabled are also settable in Interface Builder

<br>
Sample Images
----------
###normal

![failed normal](http://klieme.com/Images/failed.tif)
![caution normal](http://klieme.com/Images/caution.tif)
![success normal](http://klieme.com/Images/success.tif)
![processing](http://klieme.com/Images/processing.png)
###inverted
![failed inverted](http://klieme.com/Images/failed_inverted.tif)
![caution inverted](http://klieme.com/Images/caution_inverted.tif)
![success inverted](http://klieme.com/Images/success_inverted.tif)


<br>
System Requirements
-------------------

Mac OS 10.9 Mavericks or higher
