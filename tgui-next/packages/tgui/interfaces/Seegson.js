import { map } from 'common/collections';
import { Fragment } from 'inferno';
import { act } from '../byond';
import { AnimatedNumber, Box, Button, LabeledList, Section, Tabs } from '../components';

export const Seegson = props => {
  const { state } = props;
  const { config, data } = state;
  const { ref } = config;
  const entries = data.Entries || {};
  return (
    <Section>
      {Object.keys(data.launchers_info).map(key => {
        let value = data.launchers_info[key];
        return (
          <Fragment key={key}>
            <Section title={`${value.name}`}>
              {!!value.mag_locked && (
                <Fragment>
                  <Button
                    content={`Launch ${value.mag_locked}`}
                    icon="arrow-right"
                    color={"good"}
                    disabled={!value.can_launch}
                    onClick={() => act('launch', { id: value.id })} />
                  <Button
                    content={`Release ${value.mag_locked}`}
                    icon="eject"
                    color={"average"}
                    onClick={() => act('release', { id: value.id })} />
                </Fragment>
              )}
            </Section>
          </Fragment>);
      })}
    </Section>
  );
};
