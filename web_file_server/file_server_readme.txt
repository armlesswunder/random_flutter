::: Prerequisites :::
install and configure python on your local machine

::: For Users :::

:: Initialize a server ::

Run the following command in the desired directory:
python3 -m file_server

Use the web address path editor in app to navigate directories.

::: For Developers ::: 

:: Make Requests ::

: Get files :
GET http://localhost:8001/child_folder_name

: Get file content :
GET http://localhost:8001/child_folder_name/child.txt

: Update file content / Create file with content :
PUT http://localhost:8001/child_folder_name/child.txt 

Request body:
the request's RAW TEXT will be writen as the file's entire content

If the file doesn't exist, it will be created


: Delete file :
DELETE http://localhost:8001/child_folder_name/child.txt