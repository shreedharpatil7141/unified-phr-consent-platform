import { useEffect, useState } from "react";

const buildCountdownState = (expiresAt) => {
  if (!expiresAt) {
    return {
      label: "No expiry available",
      tone: "neutral",
    };
  }

  const diff = new Date(expiresAt) - new Date();
  if (diff <= 0) {
    return {
      label: "Expired",
      tone: "expired",
    };
  }

  const totalSeconds = Math.floor(diff / 1000);
  const days = Math.floor(totalSeconds / 86400);
  const hours = Math.floor((totalSeconds % 86400) / 3600);
  const minutes = Math.floor((totalSeconds % 3600) / 60);
  const seconds = totalSeconds % 60;
  const tone = totalSeconds <= 900 ? "warning" : "active";

  if (days > 0) {
    return {
      label: `${days}d ${hours}h ${minutes}m remaining`,
      tone,
    };
  }

  if (hours > 0) {
    return {
      label: `${hours}h ${minutes}m ${seconds}s remaining`,
      tone,
    };
  }

  return {
    label: `${minutes}m ${seconds}s remaining`,
    tone,
  };
};

const ConsentTimer = ({ expiresAt }) => {
  const [countdown, setCountdown] = useState(buildCountdownState(expiresAt));

  useEffect(() => {
    setCountdown(buildCountdownState(expiresAt));
    if (!expiresAt) return undefined;

    const interval = setInterval(() => {
      setCountdown(buildCountdownState(expiresAt));
    }, 1000);

    return () => clearInterval(interval);
  }, [expiresAt]);

  return (
    <div className={`consent-timer consent-timer-${countdown.tone}`}>
      {countdown.label}
    </div>
  );
};

export default ConsentTimer;
