import { AboutPage } from '@/components/prepzi/info-pages'
import { getSiteSettings } from '@/lib/queries'

export const metadata = { title: 'About Us — Prepzi' }

export default async function About() {
  const settings = await getSiteSettings()
  return <AboutPage settings={settings} />
}
