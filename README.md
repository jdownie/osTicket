# osTicket

## TLDR;

```
mkdir /tmp/otdb
docker run --rm -d --name otdb -v "/tmp/otdb:/var/lib/mysql" -e "MYSQL_ROOT_PASSWORD=osticket" mysql
docker run --rm -d --name otapp -p "2180:80" --link "otdb:otdb" -v "/tmp/ost-config.php:/app/include/ost-config.php" jdownie/osticket:1.15.3
```

## Getting Started

You can (but shouldn't) launch this image with something like this...

```
docker run --rm -ti jdownie/osticket:1.15.3
```

The `--rm` and `-ti` options are my own personal habbits with docker. I use `--rm` so that I don't end up with a lot of dead containers that I then have to clean up with a bunch of `docker rm` calls. The `-ti` is so that I can see what happens inside that container, and maybe even interfere with it with a Ctrl + C. We'll replace these two switches with a `-d` later (when we want this container to run as a service instead of something that we're directly fiddling with and observing while we learn how it works.

Anyway, that example won't get you far. You'll get this...

```
File missing: /app/include/ost-config.php
Did you forget to map your configuration file with docker-run's -v switch?
```

There are two parts of this docker container that you'll want to keep "outside" of this container so that they can be backed up, and can persist through upgrades and container instances. Those external parts are...

1. A MySQL server instance hosting your osTicket database
2. Your osTicket configuration, detailing (among other things) how to connect to that MySQL server.

You may already have your own MySQL server, and will therefor have no interest in the information in this README about hosting your own MySQL instance. Either way, you will want your own `ost-config.php` file that you'll need to map through to your container with `docker-run`'s `-v`switch. There is a default example included in this repository

There is a sample file included in osTicket's source code, (that is also inside this osTicket image) that you can pull out with this statement...

```
docker run --rm -ti jdownie/osticket:1.15.3 cat /src/include/ost-sampleconfig.php > /tmp/ost-config.php
```

That statement will run up an instance of `osticket:1.15.3` long enough to run one command; `cat /src/include/ost-sampleconfig.php`. The last part; `> /tmp/ost-config.php` just takes the contents of that file and dumps it in `/tmp/ost-config.php`. This is not a very good example. You may have your own special area for these kinds of persistent docker configuration files. If so, please use that instead of my dumb `/tmp` example. Now that we have this file in our own persistent storage location we can try our earlier statement with that `-v` option...

```
docker run --rm -ti -v "/tmp/ost-config.php:/app/include/ost-config.php" jdownie/osticket:1.15.3
```

This will have satisfied `osticket:1.15.3`'s earlier complaint. Our own `/tmp/ost-config.php` file is being presented through to our container instance in the location that it's required in; `/app/include/ost-config.php`. So now we get this output...

```
.AH00558: apache2: Could not reliably determine the server's fully qualified domain name, using 172.17.0.6. Set the 'ServerName' directive globally to suppress this message
```

Which is actually a good thing. That's just apache telling us that we've been a little lazy in our configuration file - which doesn't bother us right now. The problem that we will have now is that apache is listening on tcp/80 inside that container, but we can't get to that from outside. Let's stop our container by pressing Ctrl + C and launch it again with this...

```
docker run --rm -ti -p "2180:80" -v "/tmp/ost-config.php:/app/include/ost-config.php" jdownie/osticket:1.15.3
```

I already have something listening on tcp/80 on the machine that i'm testing all of this on, so i'm presenting this containers tcp/80 on the host's tcp/2180. The IP address of the host that i'm running all of this on is `192.168.1.3`, so from another desktop on my network i'm able to browse to `http://192.168.1.3:2180/`. This will redirect us to `/setup/install.php` which will tell us that our image has all of the dependencies installed, and prompt us to click the "Continue" button.

Now you'll be able to answer a few questions to get your osTicket instance set up. To go any further you'll need a MySQL server available. If you're one of the people that I mentioned earlier that already has a MySQL server available, the instructions that you've just read through are probably sufficient for your needs. If however you're somebody that wants help with that too, read on.

Before we finish off here though, let's change one last thing. Instead of `-ti`, let's try `-d`...

```
docker run --rm -d -p "2180:80" -v "/tmp/ost-config.php:/app/include/ost-config.php" jdownie/osticket:1.15.3
```

When we run that, docker won't say much about the new container. We'll be able to see it with `docker ps`, see what's going on inside that container with a `docker logs` and kill it with `docker stop`.

## Hosting your own MySQL Instance

In the earlier instructions we hosted our persisitent `ost-config.php` file in `/tmp` which is obviously not a very good example in practice. I'm going to do exactly the same thing here, so I encourage you to come up with your own persistent docker configuration folder (and not learn this bad practice from these notes). I'm only doing this here because we all have a `/tmp` folder, and it can be distractin to read about somebody else's file system habits.

Spinning up a MySQL server is very easy. We will however need a storage location for the database files, so let's first create that folder (in `/tmp`)..

```
mkdir /tmp/otdb
```

...and now let's start our MySQL server...

```
docker run -d --rm -v "/tmp/otdb:/var/lib/mysql" -e "MYSQL_ROOT_PASSWORD=osticket" --name otdb mysql
```

This one is a little different to our earlier examples. We're still using `--rm` so that this container will vanish when it stops, but this time instead of `-ti` we're running `-d` which runs the container in the background instead of in the foreground. If you were to look inside `/tmp/otdb` now you'll find a lot of files because the mysql image will happily move into it's new home and set up the essentials when it first starts.

Now that we have that `otdb` container running, we can launch our osTicket image in such a way that it's aware of it's existence...

```
docker run --rm -d --name otapp -p "2180:80" --link "otdb:otdb" -v "/tmp/ost-config.php:/app/include/ost-config.php" jdownie/osticket:1.15.3
```

You might notice that I also took the opportunity to give our application container a name, so that the app is called `otapp` and the database server is called `otdb`. The `--link "otdb:otdb"` switch means that the container named `otdb` will be made available to `otapp` as if it's a host on the same network called `otdb`. We could have called it anything in this linking, but there wasn't anything to be gained by calling it one thing "outside" the `otapp` container, and then something different "inside" that container. When you complete the setup wizard, you'll be asked for the MySQL server's details. You'll be able to provide the following...

| Setting | Value |
| --- | --- |
| MySQL Hostname | `otdb` |
| MySQL Database | `osticket` |
| MySQL Username | `root` |
| MySQL Password | `osticket` |

You'll only need to do this once when you first set this up. From that point on, any changes you make to the way that you host your MySQL database need to be updated in your `ost-config.php` file.

## CRON Jobs

On a "normal" system, you'd be expected to schedule a cron job, which would routinely run `/app/api/cron.php`. Being  docker container, we'd prefer not to burden our image with something as big and complicated as `crond`, so instead the `/entrypoint` script has a perpetual `while` loop that runs that script and sleeps for a minute. It's not pretty, but it's worked well enough for me.

## Timezones

I'm not sure what impact that this setting has on this particular application, but if you find that the time is incorrect in your implementation, perhaps you'll need to change the timezone. Adding something like `-e "TZ=Australia/Perth"` might help in your `docker-run` call on the `jdownie/osticket` image.

