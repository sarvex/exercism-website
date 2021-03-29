import * as React from 'react'
import { ExerciseStatus } from './concept-map-types'

export const ExerciseStatusBar = ({
  exerciseStatuses,
}: {
  exerciseStatuses: ExerciseStatus[]
}): JSX.Element | null => {
  if (exerciseStatuses.length === 0) {
    return null
  }

  return (
    <div className="exercise-status-bar">
      {exerciseStatuses.map((status, i) => statusMapper(status, i))}
    </div>
  )
}

export const PureExerciseStatusBar = React.memo(ExerciseStatusBar)

const statusMapper = (status: ExerciseStatus, key: number): JSX.Element => {
  const className = status
    .split('_')
    .map((s) => s[0])
    .join('')
  return <div key={key} className={`c-ed --${className}`} />
}