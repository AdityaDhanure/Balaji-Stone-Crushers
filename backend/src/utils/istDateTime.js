const IST_OFFSET_MS = 5.5 * 60 * 60 * 1000;

export const IST_DATE_SQL = "(CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Kolkata')::date";
export const IST_TIMESTAMP_SQL = "CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Kolkata'";

export const nowIst = () => new Date(Date.now() + IST_OFFSET_MS);

export const todayIst = () => nowIst().toISOString().split('T')[0];

export const addDaysToDateString = (dateString, days) => {
  const base = new Date(`${dateString}T00:00:00.000Z`);
  base.setUTCDate(base.getUTCDate() + days);
  return base.toISOString().split('T')[0];
};

export const nowIstIsoString = () => {
  const value = nowIst();
  const pad = (number) => String(number).padStart(2, '0');

  return [
    value.getUTCFullYear(),
    '-',
    pad(value.getUTCMonth() + 1),
    '-',
    pad(value.getUTCDate()),
    'T',
    pad(value.getUTCHours()),
    ':',
    pad(value.getUTCMinutes()),
    ':',
    pad(value.getUTCSeconds()),
    '+05:30',
  ].join('');
};
