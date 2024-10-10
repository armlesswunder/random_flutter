# List Utility App - by ArmlessWunder
A complex, yet user friendly list utility app.

# Download

[releases](https://github.com/armlesswunder/random_flutter/releases).

Supported platforms: Windows, Android, Macos, and Web
<sub>web is supported minimally due to platform constraints).</sub>

# Contact
***Don't contact me with questions until you've read the entire guide please.*** I expect you to do some research for more technical aspects of the app before contacting me.

Email me at: abw4v.dev@gmail.com

# Guide

## How does it work?
This app accepts a file and displays the info in a neat list. 
The app can read any file that contains text or a specially formatted json file (see examples {link to json example} for exact formatting support). 
Text files are displayed in a list separated by newlines.
List items can be filtered by text (searchbar) or checkbox state.

## List screen (Top right)
On desktop, you choose where your lists are located on the list screen.
On mobile, your lists are stored in external storage (For android: ../Internal storage/Android/data/com.abw4v.random_app_flutter.random_app/files/playlists )

## Settings screen (Top right)
There are a variety of utils and settings listed here. They are all described at a high level in the app.

## Download example lists
Download examples [here](https://github.com/armlesswunder/random_flutter/blob/main/assets/presets) if you want to see the app in action

# Guide: Advanced
This section contains information for technical individuals who wish to make their own lists for the app.

## Core concepts:
**List settings:** A setting which is saved for a particular list only
**Checkboxes:** check items off your list by enabling checkboxes in list settings

## Main screen
The screen you see when you open the app. I will describe the functionality in detail here, going left to right, top to bottom:

### Count
The number of items you in the current list with all filters applied

### More options (... Icon Button)
Contains not commonly used features:

### Edit
Allows you to drag list items around to reorder the list

### Shuffle
Shuffle list items randomly

### Sort
Sorts list items by name

### Add
Add a list item on the fly

### Checked filter
You can filter out checked, or unchecked items by choosing an appropriate dropdown option

## Settings (Gear Icon Button)
Navigates to a screen with many settings and utilities

### Search (not useful)
This is kind of a dead screen. It was used to search through a list but that functionality exists on the main screen now

### Audit
View and search for changes to list items (check state and reorder state). Useful if you want to do some investigation on recent changes to the list.

Each item has a name (list item name), list name (if audit all mode), timestamp of change, and a revert/check button respectively.
Searchbar does what you'd expect. Audit current allows you to filter audit results between the current list and all lists.

### Episode generator
A utility to generate a list of episodes

Name: the name of the list you are making

Plus icon: Add a season

Season List item: enter number of episodes in the season

Remove: Remove a season

Generate episodes: Generates al list of episodes for each season

### Random tools
Some random utility tools

Random in range:
Has a start and end range. Must be a number for start and end. Press generate to create a random number in that range. Sound effect confirms it worked.

Coin toss:
Self explanatory. Sound effect confirms it worked.

### List settings
This screen is important for all users. It contains settings for the individual list.

Use favorites (not supported for web): Allows a checkbox that looks like a heart for list items, to filter items based on favorite status

Use checkboxes: show checkbox for list items. You can filter items based on checkbox state

Save scroll position: Makes the app remember the scroll position for the list. When the list loads, you will be where you left off. I think this may reset to top if you use the searchbar or something.

Note mode: For android, you can import from google notes... This is just a setting for my personal use. Don't use it, it won't do anything useful for you.

Hide Actions: Hide Move to bottom button, checkbox, and favorite button for list items.

Edit: You can edit the list in a large text editor. Useful if you want to delete/copy/paste a large number of list items on the fly

Select/Unselect all: Select or unselect all top level (list item) checkboxes

### Global settings
Unimplemented. Might contain stuff in the future

## Lists screen (List icon button)
Shows your lists. Lists are files in a directory. The directory is chosen by user on desktop, or the app's storage directory on android (../Internal storage/Android/data/com.abw4v.random_app_flutter.random_app/files/playlists)
The directory is unavailable on web or using web mode, because fundamentally web doesn't work with directories.

Move up button: Moves you to the parent directory if show directories is enabled. On android, you can't move up from the base directory (playlists)
Searchbar: You can filter your lists by name. Filtered lists can be useful because the tabs will only show lists that are filtered for your session.

More button: 

Contains list of options:

- Web files: Use the webserver file to host lists to the app. I recommend you just ignore this unless you really need to use the app on web (steam overlay maybe?)
- Show system files: Shows files and directories used by the app. I recommend you ignore this.
- Show directories: ...
- Choose default list: On desktop, choose where the app looks for lists. This is a required step on desktop.
- Add: Add a list
- Export list: For android and web, save the list somewhere
- Export all: For android and web, save all lists and data somewhere in a zip file
- Import: For android and web, import a list via file or import all app data via zip file

List items: Select a list to load its contents. Long press a list for more options

## Searchbar (Main)
Filter list items by name. Your text is saved when you switch lists, so check the query if your list looks wrong on load. Json items with searchable attribute will filter based on that value instead.

## List tabs
A list of your lists shown as tabs for quick switching. Swipe left or right on list items to switch the list as well

## List items
The core feature of the app; the list data.
List items can be simple or complex. Text files with newlines show simple text. Text lines that adhere to a list of rules can have special layouts and images (I'll cover that below)

A list item is an item in a file separated by a newline. It can be an object in a json array as well (example below).

List item actions: Checkbox, Favorite, and Move to bottom button (moves item to bottom of list).
Info button can be present for json items with info or info_list attribute

Single press a list item to copy to clipboard

Double press a list item to jump to a list matching the display item's name

Long press a list item for more options:

Remove: ...

Move up: the opposite of move down

Randomize: Move the list item to a random position in the list

JSON Beautify: *Only appears for json lists* Make the json easier to read. Will turn red if json has errors. 

Text field: Edit the list item contents.

Copy: copy to clipboard

Done: Save changes

## Json example
Complicated list data can be shown if your file is a list of json objects.
***Recommended: Only highly technical individuals should try to make a list of this type.***

[Example List](https://github.com/armlesswunder/random_flutter/blob/main/assets/presets/example.json).

## Extended list item formatting

The following can be interpreted by the app for a list item:

<nl> = Newline

<period> = period .

<comma> = comma ,

List items may have a pleasing layout if certain rules are followed. This feature can be difficult to use, so please be thorough as a list creator

anything before the first | is the title
img=\imgPath\example.png will be rendered as an image
, separates sub items
: Adds a sub header

Example:

Title| img=\path\to\image\file.png, Magic Amulet, img=\path\to\image\file.png

## Images
An image rendered on the app. Long press to zoom in on the image
If the image is from a json item, the image may have properties denounced by the image_properties attribute. Image properties mostly control how large the image is

Example:

Images in an image list that have properties:

"info_list": [
{"image": "\\persona4\\yukiko.webp", "description": "I'm only 80x80 pixels", **"image_properties":  {"width": 80, "height":  80}**},
{"image": "\\persona4\\margaret.webp", "description": "My size is not constrained", **"image_properties":  {"native_size": true}**}
],

## Web caveats
Your lists can be deleted at any time by the browser due to caching rules. Use file_server.py with web mode enabled to load files from a directory
web_server.py has a readme for more info

## Macos support
I can't release the macos version bc the zip file messes up the application for some reason and I don't care to fix it

## Ios Support
I haven't tested on ios. I may need to mess with the code to get it to check the right directories and there could be some package compatibility issues I haven't accounted for. If you want the app on ios please consider contributing the necessary changes. As with all my apps, I will not host to app store in protest to Apple's aggressive pricing.