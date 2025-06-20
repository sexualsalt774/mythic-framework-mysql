import React, { useEffect } from 'react';
import { connect, useSelector } from 'react-redux';
import { Slide } from '@mui/material';
import { makeStyles } from '@mui/styles';

import Slot from './Slot';
import { getItemImage } from './item';

const useStyles = makeStyles((theme) => ({
	slide: {
		position: "absolute",
		bottom: 20,
		left: 0,
		width: "100%",
		display: "flex",
		justifyContent: "center",
		gap: 10,
		zIndex: 1000,
	  },
	  hotbarContainer: {
		display: "flex",
		gap: 10,
		background: "rgba(13, 22, 37, 0.75)",
		//backdropFilter: "blur(10px)",
		padding: "15px 20px",
		borderRadius: 16,
		boxShadow: "0 8px 32px rgba(0, 0, 0, 0.3)",
		border: "1px solid rgba(255, 255, 255, 0.05)",
	  },
	  equipped: {
		marginLeft: 20,
		position: "relative",
		"&::before": {
		  content: '""',
		  position: "absolute",
		  left: -15,
		  top: "50%",
		  transform: "translateY(-50%)",
		  width: 1,
		  height: "80%",
		  background: "rgba(255, 255, 255, 0.1)",
		},
	  },
}));

export default connect()((props) => {
	const classes = useStyles();
	const hidden = useSelector((state) => state.app.showHotbar);
	const showing = useSelector((state) => state.app.showing);
	const hbItems = useSelector((state) => state.app.hotbarItems);
	const equipped = useSelector((state) => state.app.equipped);
	const items = useSelector((state) => state.inventory.items);
	const itemsLoaded = useSelector((state) => state.inventory.itemsLoaded);
	const playerInventory = useSelector((state) => state.inventory.player);

	const mode = useSelector((state) => state.app.mode);

	useEffect(() => {
		let tmr = null;
		if (hidden) {
			tmr = setTimeout(() => {
				props.dispatch({
					type: 'HOTBAR_HIDE',
				});
			}, 5000);

			return () => {
				clearTimeout(tmr);
			};
		}
	}, [hidden]);

	if (mode === 'crafting') {
		return null;
	}

	if (!itemsLoaded || !Boolean(hbItems) || Object.keys(items).length == 0)
		return null;
	return (
		<Slide direction="up" in={hidden} className={classes.slide}>
			<div>
				{[...Array(4).keys()].map((value) => {
					return (
						<Slot
							mini
							solid
							inHotbar={true}
							showing={showing}
							key={value + 1}
							slot={value + 1}
							owner={playerInventory.owner}
							invType={playerInventory.invType}
							hotkeys={true}
							data={
								hbItems.filter((s) => s.Slot == value + 1)
									? hbItems.filter(
											(s) => s.Slot == value + 1,
									  )[0]
									: {}
							}
						/>
					);
				})}
				{Boolean(equipped) && (
					<Slot
						mini
						solid
						equipped
						inHotbar={true}
						showing={showing}
						owner={playerInventory.owner}
						invType={playerInventory.invType}
						slot={equipped.Slot}
						hotkeys={false}
						data={equipped}
					/>
				)}
			</div>
		</Slide>
	);
});
