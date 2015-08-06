# epubify

This is a tiny web app that does:

- Accepts [IFTTT Maker](https://ifttt.com/maker) request with a URL
- Makes an anonymous [Readlists](http://readlists.com) list
- Download EPUB generated by Readlists
- Upload to Dropbox folder

Ideal use is to deploy on Heroku, then connect tagged items on Pocket/Instapaper on IFTTT. Whenever you tag an item with 'longform', it creates a new epub on your Dropbox folder.

## App Configuration

This app requires the following environment variables to run properly.

- `DROPBOX_TOKEN`: Dropbox OAuth2 token. You can create your own app and [generate a token](https://blogs.dropbox.com/developers/2014/05/generate-an-access-token-for-your-own-account/)
- `IFTTT_SECRET`: (Optional) secret parameter sent from IFTTT to verify that the request is coming from your recipe

## IFTTT configuration

This application accepts the following POST parameters. Choose "POST" method and "application/x-www-form-urlencoded" content type, with the following parameters in the body.

- `url`: URL of the page
- `title`: Title of the page
- `secret`: (Optional) secret to verify a request (see above)
