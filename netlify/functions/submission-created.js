// Telegram notification for direct enquiries.
//
// Netlify calls this automatically on every verified form submission — the
// filename is the trigger, so there is no webhook to configure. It runs after
// the submission is already stored, which means a failure here loses a
// notification but never an enquiry. That ordering is deliberate: the Forms
// dashboard stays the source of truth.
//
// Requires two environment variables, set in Netlify (never in this repo):
//   TELEGRAM_BOT_TOKEN  — from @BotFather
//   TELEGRAM_CHAT_ID    — the group id, a negative number

const esc = (s) =>
  String(s ?? '').replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');

const nightsBetween = (from, to) => {
  const a = new Date(from), b = new Date(to);
  if (isNaN(a) || isNaN(b)) return null;
  const n = Math.round((b - a) / 86400000);
  return n > 0 ? n : null;
};

const prettyDate = (v) => {
  const d = new Date(v);
  if (isNaN(d)) return v;
  return d.toLocaleDateString('en-IE', { weekday: 'short', day: 'numeric', month: 'short', year: 'numeric' });
};

exports.handler = async (event) => {
  const token  = process.env.TELEGRAM_BOT_TOKEN;
  const chatId = process.env.TELEGRAM_CHAT_ID;

  if (!token || !chatId) {
    console.error('TELEGRAM_BOT_TOKEN or TELEGRAM_CHAT_ID not set — skipping notification.');
    return { statusCode: 200, body: 'Notification skipped: missing configuration.' };
  }

  let data = {};
  try {
    data = (JSON.parse(event.body).payload || {}).data || {};
  } catch (err) {
    console.error('Could not parse submission payload:', err);
    return { statusCode: 200, body: 'Unparseable payload; submission itself is unaffected.' };
  }

  const isVoucher = String(data['enquiry-type'] || '').startsWith('Gift voucher');
  const lines = [];

  lines.push(isVoucher
    ? `<b>Gift voucher request</b> — ${esc(data['enquiry-type'].replace('Gift voucher — ', ''))}`
    : '<b>New enquiry</b> — 55 Malin Road');
  lines.push('');
  lines.push(`<b>Name</b>  ${esc(data.name) || '—'}`);
  lines.push(`<b>Email</b> ${esc(data.email) || '—'}`);

  if (!isVoucher) {
    if (data.arrival)   lines.push(`<b>Arrive</b> ${esc(prettyDate(data.arrival))}`);
    if (data.departure) lines.push(`<b>Depart</b> ${esc(prettyDate(data.departure))}`);
    const n = nightsBetween(data.arrival, data.departure);
    if (n) lines.push(`<b>Nights</b> ${n}`);
    if (data.guests) lines.push(`<b>Guests</b> ${esc(data.guests)}`);
  }

  if (data.message) {
    lines.push('');
    lines.push(esc(data.message));
  }

  lines.push('');
  lines.push('<a href="https://app.netlify.com/projects/55malinroad/forms">Open in Netlify</a>');

  try {
    const res = await fetch(`https://api.telegram.org/bot${token}/sendMessage`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        chat_id: chatId,
        text: lines.join('\n'),
        parse_mode: 'HTML',
        disable_web_page_preview: true
      })
    });

    if (!res.ok) {
      // Telegram returns a descriptive body; log it rather than the token.
      console.error('Telegram rejected the message:', res.status, await res.text());
    }
  } catch (err) {
    console.error('Could not reach Telegram:', err);
  }

  // Always 200. A notification problem must never look like a form problem.
  return { statusCode: 200, body: 'Done.' };
};
