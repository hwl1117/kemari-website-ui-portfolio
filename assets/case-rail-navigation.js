(() => {
  const navigation = document.querySelector('[data-rail-navigation]');
  if (!navigation || !('IntersectionObserver' in window)) return;

  const links = [...navigation.querySelectorAll('a[href^="#"]')];
  const sections = links
    .map((link) => document.querySelector(link.getAttribute('href')))
    .filter(Boolean);

  const setActive = (id) => {
    links.forEach((link) => {
      const isActive = link.getAttribute('href') === `#${id}`;
      if (isActive) link.setAttribute('aria-current', 'page');
      else link.removeAttribute('aria-current');
    });
  };

  const observer = new IntersectionObserver((entries) => {
    const visible = entries
      .filter((entry) => entry.isIntersecting)
      .sort((a, b) => b.intersectionRatio - a.intersectionRatio)[0];
    if (visible) setActive(visible.target.id);
  }, { rootMargin: '-28% 0px -52% 0px', threshold: [0.1, 0.35, 0.65] });

  sections.forEach((section) => observer.observe(section));
  links.forEach((link) => link.addEventListener('click', () => setActive(link.hash.slice(1))));
})();
