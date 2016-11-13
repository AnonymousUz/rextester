Telegram bot for executing snippets of code.

"Official" deploy: [@rextester_bot][1]

## Setup ##

    npm install

    # without angle brackets
    export TELEGRAM_BOT_TOKEN=<Telegram bot token>
    # alternatively, you can put your token in token.json

    # if the app is behind https => http proxy,
    # and you wish to use Webhook, set also these:
    export NOW_URL=https://<url to set webhook to>
    export PORT=<port to listen to updates on>

    # For every request to execute some code,
    # the bot stores some info in memory, so that in case of edit
    # it knows which message to update. Set that var to X
    # to clear data about messages older than X seconds, for example
    export SECS_TO_EDIT=600 # clear data about messages older than 10 minutes.
    # If you don't set it, bot will never clear any info,
    # which means it'll eventually take **all** available memory,
    # and it'll print a warning. If not clearing is what you want,
    # (for example because bot is periodically restarted)
    # set it to empty string to suppress the warning:
    export SECS_TO_EDIT=

    npm start

[1]: https://telegram.me/rextester_bot
