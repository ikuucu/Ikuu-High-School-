# Ikuu Boys High School CU website: login and admin inbox

This folder has three files:

- `index.html` is the whole website (all pages, sign in, create account, member area and admin inbox).
- `supabase-setup.sql` creates the database tables and security rules.
- `README.md` is this guide.

Members create an account with email and password, then send messages, prayer requests, testimonies or questions. Admins read them in the **Admin inbox**, mark them read, reply, or delete them. Members see the replies in their account.

Accounts and messages are stored in **Supabase** (free plan is enough). You host the site somewhere free, such as Netlify.

## Setup (about 15 minutes)

### 1. Create the database
1. Go to supabase.com, sign up, and click **New project**. Pick a name and a strong database password, then wait for it to finish.
2. Open **SQL Editor > New query**, paste everything from `supabase-setup.sql`, and click **Run**.

### 2. Adjust sign-in settings
Open **Authentication** and check:
- **Sign In / Providers > Email**: email sign-in is on. Set the minimum password length to **8**.
- **Confirm email**: by default new members must click a link in an email before they can sign in. Supabase's built-in email sender only sends a few emails per hour, so for a school you may prefer to turn **Confirm email** off. The site works either way.

### 3. Connect the site to your database
1. In Supabase open **Project Settings > API**.
2. Copy the **Project URL** and the **anon public** key.
3. Open `index.html` in a text editor, find `SITE SETTINGS` near the bottom, and replace `YOUR_SUPABASE_URL` and `YOUR_SUPABASE_ANON_KEY`.

The anon key is designed to be public. The security rules from step 1 protect the data. **Never** paste the `service_role` key into the website.

### 4. Put the site online
Easiest: go to app.netlify.com/drop and drag the folder in. GitHub Pages and Cloudflare Pages also work. The site will not work when opened from the Supabase or Claude preview links, because those block outside connections.

After it is live, go to Supabase **Authentication > URL Configuration** and set **Site URL** to your website address.

### 5. Make yourself the admin
1. On your live site, click **Sign in > Create an account** and register with the email and password you want for the admin.
2. In Supabase **SQL Editor**, run this once, using your email:

```sql
insert into public.admins (user_id)
select id from auth.users where email = 'your-admin-email@example.com';
```

3. Sign in on the site. You will land on the **Admin inbox**. You can add more admins by running the same statement for their email.

## About the admin password
The admin password is the one you choose when you register in step 5. It is never written into the website's code, so nobody can read it by viewing the page source. Pick a long password. Eight digits can be guessed quickly, and a password shared in a chat should be treated as no longer private. If you forget a password, reset it in Supabase **Authentication > Users**.

## What is protected
- Only signed-in members can send messages, and only as themselves.
- Members can read only their own messages. Admins can read, reply to, and delete all messages.
- Message text is always shown as plain text, so nothing a member types can run as code.

## Not included
- There is no "forgot password" screen. Reset passwords from the Supabase dashboard.
- There are no email or SMS alerts for new messages. The Admin link in the menu shows a count of new messages.
- Nothing stops a member from sending many messages. If that becomes a problem, ask and we can add a limit.

## Note on testing
I tested the pages end to end against a stand-in for Supabase (sign up, sign in, page guards, sending, replying, deleting). I could not test against a live Supabase project from here, so do a quick trial with two accounts after setup: send a message as a member, then read and reply as the admin.
