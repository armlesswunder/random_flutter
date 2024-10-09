# random_flutter
A complex, yet user friendly list utility app.
Supported platforms: Windows, Android, Macos, and Web (web is supported minimally due to platform constraints).

# How does it work?
This app accepts a file and displays the info in a neat list. 
The app can read any file that contains text or a specially formatted json file (see examples for exact formatting support). 
Text files are displayed in a list separated by newlines.
List items can be filtered by text (searchbar) or checkbox state.

# List screen (Top right)
On desktop, you choose where your lists are located on the list screen.
On mobile, your lists are stored in external storage (For android: ../andorid/data/com.abw4v.random_app/playlists )

# Settings screen (Top right)
There are a variety of utils and settings listed here. They are all described well enough in the app.

# Json example
Complicated list data can be shown if your file is a list of json objects.
! Recommended: Only highly technical individuals should try to make a list of this type.

Example list:
[
    {
    "title": "Some title text",
    "description": "Some subtitle text",
    "info": "a simple bit of info that can popup via info button. more complicated info can be displayed in the info_list property below",
    "info_list": [
        {
            "description": "Im the simplest info list item",
        },
        {
            "image": "\\test\\sub_item.png",
            "description": "You can select me and I have an image!",
            "selected": false
        }
    ],
    "searchable": "Something you can filter in searchbar",
    "image": "\\test\\example.png"
    }
]