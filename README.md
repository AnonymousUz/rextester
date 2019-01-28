**No longer maintained. I'm working on a [rewrite][4].**

Telegram bot for executing snippets of code.

"Official" deploy: [@rextester_bot][1]

## Setup ##

```bash
git clone https://bitbucket.org/GingerPlusPlus/rextester-bot.git
cd rextester-bot
npm install
# configure the bot, read further
npm start
```

## Configuration ##

You can configure the bot using environmental variables.
In Bash, they can be set using `export <NAME>=<VALUE>` syntax.

### Basic ###

- `TELEGRAM_BOT_TOKEN` (required) -- the token received from [@BotFather][2]. Alternatively, you can put your token in `token.json`.

### Webhook ###

- `NOW_URL` -- url to set webhook to
- `PORT` -- port to listen to updates on

### Redis ###

- `REDIS_URL` (optional) -- [`redis://` URL or path to unix socket][3]. If omitted, bot will start without Redis and some non-core functionality will not be available.
- `ALIAS_STATS` (optional, requires Redis) -- set to anything to enable counting how many times each alias is used by users. It's disabled by default, cause I believe it's one of the worst things that can happen to Redis persistance.
- `MAX_ALIASES_PER_USER` (defaults to 30) -- limits how many custom aliases single user can set, to prevent abuse of the database.
- `MAX_ALIAS_LENGTH` (defaults to 32) -- limits length of alias name lengths user is able to create, and disables couting of using such aliases for purpose of `ALIAS_STATS`, to prevent abuse of the database.

### Misc ###

- `SECS_TO_EDIT` -- for every command requesting code execution, the bot stores some **state**, to know which message should be edited in case the message with command gets edited. This variable defines how often that state should be purged. Set to empty string to never clean and let the bot eat all your memory.


[1]: https://telegram.me/rextester_bot
[2]: https://telegram.me/BotFather
[3]: https://github.com/luin/ioredis#connect-to-redis
[4]: https://github.com/GingerPlusPlus/Rextester-bot-v3
